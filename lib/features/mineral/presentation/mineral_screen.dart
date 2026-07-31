import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/native/astro_engine_bindings.dart';

/// Parâmetros da "Lua Mineral" (realce da cor mineral real da Lua). Os valores
/// padrão já produzem um resultado colorido de cara — o usuário refina.
class MineralParams {
  const MineralParams({
    this.saturation = 2.3,
    this.vibrance = 1.5,
    this.colorNoise = 0.15,
    this.falseColor = 0.5,
    this.intensity = 1.0,
    this.warmth = 0.0,
    this.fullDisc = false,
  });

  final double saturation;
  final double vibrance;
  final double colorNoise;
  final double falseColor;
  final double intensity;
  final double warmth;
  final bool fullDisc;

  static const defaults = MineralParams();

  MineralParams copyWith({
    double? saturation,
    double? vibrance,
    double? colorNoise,
    double? falseColor,
    double? intensity,
    double? warmth,
    bool? fullDisc,
  }) {
    return MineralParams(
      saturation: saturation ?? this.saturation,
      vibrance: vibrance ?? this.vibrance,
      colorNoise: colorNoise ?? this.colorNoise,
      falseColor: falseColor ?? this.falseColor,
      intensity: intensity ?? this.intensity,
      warmth: warmth ?? this.warmth,
      fullDisc: fullDisc ?? this.fullDisc,
    );
  }
}

/// Editor da Lua Mineral. Dois modos:
///  • ESTÚDIO (home): recebe [sourcePath] de uma imagem escolhida → salva na
///    galeria ao aplicar.
///  • RESULTADO (pós-empilhamento): sem [sourcePath] → grada o mestre do stack
///    e substitui o mestre (replaceStackMaster), como o ajuste de wavelets.
class MineralScreen extends ConsumerStatefulWidget {
  const MineralScreen({super.key, this.sourcePath, this.sourcePreview});

  /// Se dado, modo ESTÚDIO (imagem única escolhida na home). Senão, modo
  /// RESULTADO (usa o `stackResult` do rascunho).
  final String? sourcePath;
  final String? sourcePreview;

  @override
  ConsumerState<MineralScreen> createState() => _MineralScreenState();
}

class _MineralScreenState extends ConsumerState<MineralScreen> {
  MineralParams _p = MineralParams.defaults;

  String? _masterPath; // full-res de entrada
  String? _displayOriginal; // exibição antes do grade (JPG/PNG; TIFF usa prévia)
  String? _previewPath; // prévia graduada do ajuste atual
  Directory? _tmpDir;

  bool get _studio => widget.sourcePath != null;
  bool _rendering = false;
  bool _applying = false;
  Timer? _debounce;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    if (_studio) {
      _masterPath = widget.sourcePath;
      _displayOriginal = widget.sourcePreview ?? widget.sourcePath;
    } else {
      final result = ref.read(projectDraftProvider).stackResult;
      if (result != null) {
        _masterPath = result.outputPath;
        final isTiff = result.outputPath.endsWith('.tif') ||
            result.outputPath.endsWith('.tiff');
        _displayOriginal = isTiff ? result.previewPath : result.outputPath;
      }
    }
    getTemporaryDirectory().then((d) {
      _tmpDir = d;
      _render(); // já mostra colorido de cara
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), _render);
  }

  Future<void> _render() async {
    final master = _masterPath;
    final tmp = _tmpDir;
    if (master == null || tmp == null) return;
    final seq = ++_seq;
    setState(() => _rendering = true);
    final outPath = '${tmp.path}/mineral_preview_$seq.jpg';
    try {
      await mineralAdjustIsolate(
        inPath: master,
        outPath: outPath,
        saturation: _p.saturation,
        vibrance: _p.vibrance,
        colorNoise: _p.colorNoise,
        falseColor: _p.falseColor,
        intensity: _p.intensity,
        warmth: _p.warmth,
        fullDisc: _p.fullDisc,
        maxDim: 1100,
      );
    } catch (_) {
      if (seq == _seq && mounted) setState(() => _rendering = false);
      return;
    }
    if (seq != _seq) {
      _tryDelete(outPath);
      return;
    }
    if (!mounted) return;
    final old = _previewPath;
    setState(() {
      _previewPath = outPath;
      _rendering = false;
    });
    if (old != outPath) _tryDelete(old);
  }

  void _tryDelete(String? path) {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  Future<void> _apply() async {
    final master = _masterPath;
    if (master == null) return;
    setState(() => _applying = true);

    if (_studio) {
      // Salva a versão graduada, em resolução cheia, na galeria.
      try {
        final tmp = _tmpDir ?? await getTemporaryDirectory();
        final ts = DateTime.now().millisecondsSinceEpoch;
        final out = '${tmp.path}/lua_mineral_$ts.jpg';
        await mineralAdjustIsolate(
          inPath: master,
          outPath: out,
          saturation: _p.saturation,
          vibrance: _p.vibrance,
          colorNoise: _p.colorNoise,
          falseColor: _p.falseColor,
          intensity: _p.intensity,
          warmth: _p.warmth,
          fullDisc: _p.fullDisc,
        );
        await Gal.putImage(out, album: 'LunarStack');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lua Mineral salva na galeria.')),
          );
          context.pop();
        }
      } catch (_) {
        if (mounted) {
          setState(() => _applying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não consegui salvar. Tente de novo.')),
          );
        }
      }
      return;
    }

    // Modo RESULTADO: grava o novo mestre + prévia e substitui no rascunho.
    try {
      final dot = master.lastIndexOf('.');
      final base = dot < 0 ? master : master.substring(0, dot);
      final ext = dot < 0 ? 'png' : master.substring(dot + 1);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final outMaster = '${base}_min_$ts.$ext';
      final outPreview = '${base}_min_${ts}_preview.jpg';

      await mineralAdjustIsolate(
        inPath: master,
        outPath: outMaster,
        saturation: _p.saturation,
        vibrance: _p.vibrance,
        colorNoise: _p.colorNoise,
        falseColor: _p.falseColor,
        intensity: _p.intensity,
        warmth: _p.warmth,
        fullDisc: _p.fullDisc,
      );
      await mineralAdjustIsolate(
        inPath: master,
        outPath: outPreview,
        saturation: _p.saturation,
        vibrance: _p.vibrance,
        colorNoise: _p.colorNoise,
        falseColor: _p.falseColor,
        intensity: _p.intensity,
        warmth: _p.warmth,
        fullDisc: _p.fullDisc,
        maxDim: 1600,
      );

      ref
          .read(projectDraftProvider.notifier)
          .replaceStackMaster(outputPath: outMaster, previewPath: outPreview);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lua Mineral aplicada. Agora é só exportar.')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _applying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não consegui aplicar. Tente valores menores.')),
        );
      }
    }
  }

  void _reset() {
    setState(() => _p = MineralParams.defaults);
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (_masterPath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lua Mineral')),
        body: const Center(child: Text('Nenhuma imagem para colorir.')),
      );
    }
    final showPath = _previewPath ?? _displayOriginal!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lua Mineral'),
        actions: [
          TextButton(
            onPressed: _applying ? null : _reset,
            child: const Text('Restaurar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 6.0,
                    clipBehavior: Clip.hardEdge,
                    child: Image.file(
                      File(showPath),
                      key: ValueKey(showPath),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      cacheWidth: 1600,
                    ),
                  ),
                  if (_rendering)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    shrinkWrap: true,
                    children: [
                      Text('Cor mineral',
                          style: Theme.of(context).textTheme.titleMedium),
                      _MineralSlider(
                        label: 'Intensidade',
                        value: _p.intensity,
                        min: 0.0,
                        max: 1.5,
                        onChanged: _applying
                            ? null
                            : (v) {
                                setState(() => _p = _p.copyWith(intensity: v));
                                _onChanged();
                              },
                      ),
                      _MineralSlider(
                        label: 'Saturação',
                        value: _p.saturation,
                        min: MineralParams.defaults.saturation,
                        max: 6.0,
                        onChanged: _applying
                            ? null
                            : (v) {
                                setState(() => _p = _p.copyWith(saturation: v));
                                _onChanged();
                              },
                      ),
                      _MineralSlider(
                        label: 'Vibração',
                        value: _p.vibrance,
                        min: MineralParams.defaults.vibrance,
                        max: 4.0,
                        onChanged: _applying
                            ? null
                            : (v) {
                                setState(() => _p = _p.copyWith(vibrance: v));
                                _onChanged();
                              },
                      ),
                      _MineralSlider(
                        label: 'Ruído de cor',
                        value: _p.colorNoise,
                        min: 0.0,
                        max: 2.0,
                        onChanged: _applying
                            ? null
                            : (v) {
                                setState(() => _p = _p.copyWith(colorNoise: v));
                                _onChanged();
                              },
                      ),
                      _MineralSlider(
                        label: 'Limpar cores falsas',
                        value: _p.falseColor,
                        min: 0.0,
                        max: 1.0,
                        onChanged: _applying
                            ? null
                            : (v) {
                                setState(() => _p = _p.copyWith(falseColor: v));
                                _onChanged();
                              },
                      ),
                      _MineralSlider(
                        label: 'Tom: frio ↔ quente',
                        value: _p.warmth,
                        min: -1.0,
                        max: 1.0,
                        onChanged: _applying
                            ? null
                            : (v) {
                                setState(() => _p = _p.copyWith(warmth: v));
                                _onChanged();
                              },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aplicar no disco inteiro'),
                        subtitle: const Text('Leva a cor até a borda, sem faixa incolor'),
                        value: _p.fullDisc,
                        onChanged: _applying
                            ? null
                            : (v) {
                                setState(() => _p = _p.copyWith(fullDisc: v));
                                _onChanged();
                              },
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _applying ? null : _apply,
                        icon: _applying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_studio ? Icons.save_alt : Icons.check),
                        label: Text(_applying
                            ? (_studio ? 'Salvando...' : 'Aplicando...')
                            : (_studio ? 'Salvar na galeria' : 'Aplicar cor')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MineralSlider extends StatelessWidget {
  const _MineralSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Leitura relativa: 0% = valor mínimo (nada além do padrão), 100% = máximo.
    final pct = (((value - min) / (max - min)) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('$pct%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
