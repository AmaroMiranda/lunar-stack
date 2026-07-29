import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/native/astro_engine_bindings.dart';

/// Rótulos das 5 escalas do wavelet, do detalhe mais fino ao mais grosso.
const _kScaleLabels = [
  'Detalhe fino',
  'Detalhe médio-fino',
  'Detalhe médio',
  'Detalhe grosso',
  'Estrutura',
];

/// Preset "nitidez leve" — mesmos ganhos que o motor usa no empilhamento.
const _kLightSharpen = [1.30, 1.40, 1.25, 1.10, 1.0];

class WaveletScreen extends ConsumerStatefulWidget {
  const WaveletScreen({super.key});

  @override
  ConsumerState<WaveletScreen> createState() => _WaveletScreenState();
}

class _WaveletScreenState extends ConsumerState<WaveletScreen> {
  List<double> _gains = List<double>.filled(5, 1.0);
  double _denoise = 0.0;

  String? _masterPath; // arquivo full-res de entrada (mestre da pilha)
  String? _displayOriginal; // o que mostrar antes de qualquer ajuste
  String? _previewPath; // prévia renderizada do ajuste atual
  Directory? _tmpDir;

  bool _rendering = false;
  bool _applying = false;
  Timer? _debounce;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    final result = ref.read(projectDraftProvider).stackResult;
    if (result != null) {
      _masterPath = result.outputPath;
      final isTiff =
          result.outputPath.endsWith('.tif') || result.outputPath.endsWith('.tiff');
      _displayOriginal = isTiff ? result.previewPath : result.outputPath;
    }
    getTemporaryDirectory().then((d) => _tmpDir = d);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  bool get _isIdentity =>
      _denoise == 0.0 && _gains.every((g) => (g - 1.0).abs() < 1e-3);

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _render);
  }

  Future<void> _render() async {
    final master = _masterPath;
    final tmp = _tmpDir;
    if (master == null || tmp == null) return;

    // Identidade: mostra o original, sem gastar um render.
    if (_isIdentity) {
      final old = _previewPath;
      setState(() {
        _previewPath = null;
        _rendering = false;
      });
      _tryDelete(old);
      return;
    }

    final seq = ++_seq;
    setState(() => _rendering = true);
    final outPath = '${tmp.path}/wl_preview_$seq.jpg';
    try {
      await waveletSharpenIsolate(
        inPath: master,
        gains: _gains,
        denoise: _denoise,
        outPath: outPath,
        maxDim: 1100,
      );
    } catch (_) {
      if (seq == _seq && mounted) setState(() => _rendering = false);
      return;
    }
    if (seq != _seq) {
      _tryDelete(outPath); // um render mais novo já chegou
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
    } catch (_) {
      // arquivo temporário — ignorar
    }
  }

  Future<void> _apply() async {
    final master = _masterPath;
    if (master == null) return;

    // Nada a aplicar: só volta.
    if (_isIdentity) {
      if (mounted) context.pop();
      return;
    }

    setState(() => _applying = true);
    try {
      final dot = master.lastIndexOf('.');
      final base = dot < 0 ? master : master.substring(0, dot);
      final ext = dot < 0 ? 'png' : master.substring(dot + 1);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final outMaster = '${base}_wl_$ts.$ext';
      final outPreview = '${base}_wl_${ts}_preview.jpg';

      await waveletSharpenIsolate(
        inPath: master,
        gains: _gains,
        denoise: _denoise,
        outPath: outMaster,
      );
      // Prévia JPEG para exibição (o Flutter não decodifica TIFF).
      await waveletSharpenIsolate(
        inPath: master,
        gains: _gains,
        denoise: _denoise,
        outPath: outPreview,
        maxDim: 1600,
      );

      ref
          .read(projectDraftProvider.notifier)
          .replaceStackMaster(outputPath: outMaster, previewPath: outPreview);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajuste aplicado. Agora é só exportar.')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _applying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não consegui aplicar o ajuste. Tente valores menores.')),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _gains = List<double>.filled(5, 1.0);
      _denoise = 0.0;
    });
    _onChanged();
  }

  void _applyPreset() {
    setState(() {
      _gains = List<double>.from(_kLightSharpen);
      _denoise = 1.2;
    });
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(projectDraftProvider).stackResult;
    if (result == null || _masterPath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajustar detalhes')),
        body: const Center(child: Text('Nenhuma imagem para ajustar.')),
      );
    }

    final showPath = _previewPath ?? _displayOriginal!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar detalhes (wavelets)'),
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
                  ClipRect(
                    child: Image.file(
                      File(showPath),
                      key: ValueKey(showPath),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      cacheWidth: 1200,
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
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    shrinkWrap: true,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Realce por escala',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _applying ? null : _applyPreset,
                            icon: const Icon(Icons.auto_fix_high, size: 18),
                            label: const Text('Nitidez leve'),
                          ),
                        ],
                      ),
                      for (var i = 0; i < _gains.length; i++)
                        _GainSlider(
                          label: _kScaleLabels[i],
                          value: _gains[i],
                          onChanged: _applying
                              ? null
                              : (v) {
                                  setState(() => _gains[i] = v);
                                  _onChanged();
                                },
                        ),
                      const SizedBox(height: 4),
                      _GainSlider(
                        label: 'Redução de ruído',
                        value: _denoise,
                        min: 0.0,
                        max: 3.0,
                        onChanged: _applying
                            ? null
                            : (v) {
                                setState(() => _denoise = v);
                                _onChanged();
                              },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _applying ? null : _apply,
                        icon: _applying
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: Text(_applying ? 'Aplicando...' : 'Aplicar ajuste'),
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

class _GainSlider extends StatelessWidget {
  const _GainSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0.5,
    this.max = 3.0,
  });

  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value.toStringAsFixed(2), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / 0.05).round(),
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
