import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/domain/processing_stage.dart';
import '../../../core/domain/project_type.dart';
import '../../../core/widgets/astro_card.dart';
import '../../../core/widgets/astro_metric_chip.dart';
import '../../history/application/history_controller.dart';
import '../../history/domain/history_entry.dart';

/// Resultado do fluxo "Apenas estabilizar": player em loop do MP4 gerado +
/// export para a galeria.
class VideoResultScreen extends ConsumerStatefulWidget {
  const VideoResultScreen({super.key});

  @override
  ConsumerState<VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends ConsumerState<VideoResultScreen> {
  VideoPlayerController? _player;
  bool _saved = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final path = ref.read(projectDraftProvider).stabilizedVideoPath;
    if (path != null) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveToHistory());
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory() async {
    if (_saved) return;
    _saved = true;
    final draft = ref.read(projectDraftProvider);
    if (draft.metadata == null || draft.stabilizedVideoPath == null) return;
    await ref.read(historyControllerProvider.notifier).addEntry(
          HistoryEntry(
            id: const Uuid().v4(),
            name: draft.metadata!.fileName,
            createdAt: DateTime.now(),
            projectType: ProjectType.stabilization,
            status: ProcessingStage.done,
            summary:
                '${draft.stabilizedFrames} frames · ${draft.stabilizedWidth}x${draft.stabilizedHeight}',
            sourceVideoUri: draft.metadata!.uri,
          ),
        );
  }

  Future<void> _export(String path) async {
    setState(() => _exporting = true);
    try {
      await Gal.putVideo(path, album: 'LunarStack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vídeo estabilizado salvo na galeria.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não consegui salvar o vídeo na galeria.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(projectDraftProvider);
    final path = draft.stabilizedVideoPath;

    if (path == null) {
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

    final player = _player;
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: player != null && player.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: player.value.aspectRatio,
                      child: VideoPlayer(player),
                    )
                  : const AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
            const SizedBox(height: 16),
            AstroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vídeo estabilizado', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AstroMetricChip(label: '${draft.stabilizedFrames} frames'),
                      AstroMetricChip(
                          label: '${draft.stabilizedWidth}x${draft.stabilizedHeight}'),
                      AstroMetricChip(label: 'Lua centralizada'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _exporting ? null : () => _export(path),
              icon: _exporting
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: const Text('Salvar na galeria'),
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
