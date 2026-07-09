import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/domain/processing_stage.dart';
import '../../../core/domain/stack_config.dart';
import '../../../core/native/astro_engine_bindings.dart';
import '../../../core/native/frame_extractor_channel.dart';
import '../../../core/widgets/astro_before_after_viewer.dart';
import '../../../core/widgets/astro_card.dart';
import '../../../core/widgets/astro_metric_chip.dart';
import '../../history/application/history_controller.dart';
import '../../history/domain/history_entry.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _saved = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveToHistory());
  }

  Future<void> _saveToHistory() async {
    if (_saved) return;
    _saved = true;

    final draft = ref.read(projectDraftProvider);
    if (draft.projectType == null || draft.metadata == null || draft.stackResult == null) return;

    await ref.read(historyControllerProvider.notifier).addEntry(
          HistoryEntry(
            id: const Uuid().v4(),
            name: draft.metadata!.fileName,
            createdAt: DateTime.now(),
            projectType: draft.projectType!,
            status: ProcessingStage.done,
            summary: '${draft.stackResult!.framesStacked} frames · ${draft.stackResult!.stackingMethod.label}',
            sourceVideoUri: draft.metadata!.uri,
          ),
        );
  }

  /// Opens the format chooser. The stack master is written once (format from
  /// the config screen); export re-encodes on demand so the user can pull any
  /// of the three formats from the same result.
  Future<void> _chooseAndExport(String masterPath) async {
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
    await _export(masterPath, format);
  }

  Future<void> _export(String masterPath, OutputFormat format) async {
    setState(() => _exporting = true);
    try {
      // Re-encode only when the master isn't already in the chosen format.
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
        // A galeria do Android não hospeda/exibe TIFF — vai para a pasta
        // pública Downloads/LunarStack, pronta pra abrir no editor.
        final saved = await FrameExtractorChannel()
            .saveToDownloads(path: path, mime: 'image/tiff');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('TIFF 16-bit salvo em $saved.')),
          );
        }
      } else {
        await Gal.putImage(path, album: 'LunarStack');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${format.label} salvo na galeria.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              format == OutputFormat.tiff
                  ? 'Não consegui salvar o TIFF em Downloads. Tente PNG ou JPEG.'
                  : 'Não consegui salvar na galeria.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _formatDuration(int ms) {
    final totalSeconds = ms / 1000;
    if (totalSeconds < 60) return '${totalSeconds.toStringAsFixed(1)}s';
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).round();
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(projectDraftProvider);
    final result = draft.stackResult;

    if (result == null || draft.referenceFramePath == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resultado'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: const Center(child: Text('Nenhum resultado disponível.')),
      );
    }

    // Flutter can't decode TIFF — show the JPEG preview the engine writes
    // alongside it; the full 16-bit file is what gets exported.
    final isTiff = result.outputPath.endsWith('.tif') || result.outputPath.endsWith('.tiff');
    final displayPath = isTiff ? result.previewPath : result.outputPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AstroBeforeAfterViewer(
              // cacheWidth bounds the decode: the masters are ~8 MP and the
              // viewer redraws on every slider drag frame — full-res textures
              // here turn the drag into seconds-per-frame jank (ANR on slow
              // GPUs). ~1440px is above the on-screen size, visually lossless.
              before: Image.file(
                File(draft.referenceFramePath!),
                fit: BoxFit.cover,
                cacheWidth: 1440,
              ),
              after: Image.file(
                File(displayPath),
                fit: BoxFit.cover,
                cacheWidth: 1440,
              ),
            ),
            const SizedBox(height: 16),
            AstroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Imagem empilhada', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AstroMetricChip(
                          label:
                              '${result.framesStacked} de ${result.framesAnalyzed} frames (melhores ${draft.stackConfig.frameSelectionPercent}%)'),
                      AstroMetricChip(label: result.stackingMethod.label),
                      AstroMetricChip(label: '${result.width}x${result.height}'),
                      AstroMetricChip(label: _formatDuration(result.processingTimeMs)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _exporting ? null : () => _chooseAndExport(result.outputPath),
              icon: _exporting
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: const Text('Exportar imagem'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(projectDraftProvider.notifier).reset();
                context.go('/');
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo projeto'),
            ),
          ],
        ),
      ),
    );
  }
}
