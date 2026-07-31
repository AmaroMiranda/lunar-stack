import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/domain/project_type.dart';
import '../../../core/domain/stack_config.dart';
import '../../../core/native/astro_engine_bindings.dart';
import '../../../core/native/frame_extractor_channel.dart';
import '../../../core/widgets/astro_card.dart';
import '../../../core/widgets/astro_metric_chip.dart';
import '../domain/history_entry.dart';

/// Reabre um projeto salvo no histórico só para VER e RE-EXPORTAR o resultado.
/// Não reidrata o rascunho (não re-salva no histórico nem toca no pipeline) —
/// trabalha direto no arquivo final guardado na entrada.
class SavedResultScreen extends ConsumerStatefulWidget {
  const SavedResultScreen({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  ConsumerState<SavedResultScreen> createState() => _SavedResultScreenState();
}

class _SavedResultScreenState extends ConsumerState<SavedResultScreen> {
  VideoPlayerController? _player;
  bool _exporting = false;

  bool get _isVideo => widget.entry.projectType == ProjectType.stabilization;

  @override
  void initState() {
    super.initState();
    final path = widget.entry.resultPath;
    if (_isVideo && path != null && File(path).existsSync()) {
      _player = VideoPlayerController.file(File(path))
        ..initialize().then((_) {
          if (!mounted) return;
          _player!
            ..setLooping(true)
            ..setVolume(0)
            ..play();
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _exportVideo(String path) async {
    setState(() => _exporting = true);
    try {
      await Gal.putVideo(path, album: 'LunarStack');
      _toast('Vídeo salvo na galeria.');
    } catch (_) {
      _toast('Não consegui salvar o vídeo na galeria.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _chooseAndExportImage(String masterPath) async {
    final format = await showModalBottomSheet<OutputFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('PNG'),
              subtitle: const Text('Sem perdas · salvo na galeria'),
              onTap: () => Navigator.pop(context, OutputFormat.png),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('JPEG'),
              subtitle: const Text('Arquivo menor · salvo na galeria'),
              onTap: () => Navigator.pop(context, OutputFormat.jpeg),
            ),
            ListTile(
              leading: const Icon(Icons.raw_on_outlined),
              title: const Text('TIFF 16-bit'),
              subtitle: const Text('Bruto para edição · salvo em Downloads/LunarStack'),
              onTap: () => Navigator.pop(context, OutputFormat.tiff),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (format == null || !mounted) return;
    await _exportImage(masterPath, format);
  }

  Future<void> _exportImage(String masterPath, OutputFormat format) async {
    setState(() => _exporting = true);
    try {
      final dot = masterPath.lastIndexOf('.');
      final base = dot < 0 ? masterPath : masterPath.substring(0, dot);
      final masterExt = dot < 0 ? '' : masterPath.substring(dot + 1).toLowerCase();
      final wantedExt = format.extension;
      String path;
      if (masterExt == wantedExt || (masterExt == 'tiff' && wantedExt == 'tif')) {
        path = masterPath;
      } else {
        path = '$base.$wantedExt';
        if (!File(path).existsSync()) {
          await convertImageIsolate(inPath: masterPath, outPath: path);
        }
      }

      if (format == OutputFormat.tiff) {
        final saved = await FrameExtractorChannel()
            .saveToDownloads(path: path, mime: 'image/tiff');
        _toast('TIFF 16-bit salvo em $saved.');
      } else {
        await Gal.putImage(path, album: 'LunarStack');
        _toast('${format.label} salvo na galeria.');
      }
    } catch (_) {
      _toast(format == OutputFormat.tiff
          ? 'Não consegui salvar o TIFF em Downloads. Tente PNG ou JPEG.'
          : 'Não consegui salvar na galeria.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final path = e.resultPath;
    final exists = path != null && File(path).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(e.name, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: !exists
            ? _MissingFile(isVideo: _isVideo)
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _isVideo ? _videoView() : _imageView(e),
                  ),
                  const SizedBox(height: 16),
                  AstroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.projectType.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AstroMetricChip(label: e.summary),
                            if (e.resultWidth != null && e.resultHeight != null)
                              AstroMetricChip(label: '${e.resultWidth}x${e.resultHeight}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _isVideo
                            ? _exportVideo(path)
                            : _chooseAndExportImage(path),
                    icon: _exporting
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: Text(_isVideo ? 'Salvar na galeria' : 'Exportar imagem'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _videoView() {
    final player = _player;
    if (player != null && player.value.isInitialized) {
      return AspectRatio(
        aspectRatio: player.value.aspectRatio,
        child: VideoPlayer(player),
      );
    }
    return const AspectRatio(
      aspectRatio: 9 / 16,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _imageView(HistoryEntry e) {
    // Flutter não decodifica TIFF: usa a prévia JPEG quando o mestre é TIFF.
    final master = e.resultPath!;
    final isTiff = master.endsWith('.tif') || master.endsWith('.tiff');
    final show = isTiff ? (e.previewPath ?? master) : master;
    return Image.file(
      File(show),
      fit: BoxFit.cover,
      cacheWidth: 1440,
      errorBuilder: (context, error, stack) => Container(
        color: Colors.black,
        height: 220,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
      ),
    );
  }
}

class _MissingFile extends StatelessWidget {
  const _MissingFile({required this.isVideo});
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'O arquivo deste projeto não está mais disponível.\n'
              'Ele pode ter sido apagado ou movido.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
