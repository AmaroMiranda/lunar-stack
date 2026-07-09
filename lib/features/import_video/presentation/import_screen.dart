import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/domain/video_metadata.dart';
import '../../../core/widgets/astro_button.dart';
import '../../../core/widgets/astro_card.dart';
import '../../../core/widgets/astro_metric_chip.dart';
import '../../../core/widgets/astro_warning_box.dart';
import '../application/import_controller.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(importControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Importar vídeo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (importState.status) {
            ImportStatus.idle => _EmptyImport(
                onPick: () => ref.read(importControllerProvider.notifier).pickVideo(),
              ),
            ImportStatus.picking => const Center(child: CircularProgressIndicator()),
            ImportStatus.error => _ImportError(
                message: importState.errorMessage ?? 'Não consegui importar esse vídeo.',
                onRetry: () => ref.read(importControllerProvider.notifier).pickVideo(),
              ),
            ImportStatus.ready => _ImportReady(
                controller: importState.previewController!,
                metadata: importState.metadata!,
                onChangeVideo: () => ref.read(importControllerProvider.notifier).pickVideo(),
                onContinue: () {
                  ref.read(projectDraftProvider.notifier).setVideo(importState.metadata!);
                  context.push('/flow');
                },
              ),
          },
        ),
      ),
    );
  }
}

class _EmptyImport extends StatelessWidget {
  const _EmptyImport({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Selecione um vídeo da Lua na sua galeria para começar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AstroButton(label: 'Selecionar vídeo', icon: Icons.add, onPressed: onPick),
        ],
      ),
    );
  }
}

class _ImportError extends StatelessWidget {
  const _ImportError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AstroWarningBox(message: message, severity: AstroWarningSeverity.warning),
          const SizedBox(height: 20),
          AstroButton(label: 'Tentar novamente', icon: Icons.refresh, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _ImportReady extends StatelessWidget {
  const _ImportReady({
    required this.controller,
    required this.metadata,
    required this.onChangeVideo,
    required this.onContinue,
  });

  final VideoPlayerController controller;
  final VideoMetadata metadata;
  final VoidCallback onChangeVideo;
  final VoidCallback onContinue;

  String _formatDuration(int ms) {
    final totalSeconds = (ms / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        const SizedBox(height: 16),
        AstroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metadata.fileName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AstroMetricChip(label: '${metadata.width}x${metadata.height}'),
                  AstroMetricChip(label: '${metadata.fps.toStringAsFixed(0)} fps (estimado)'),
                  AstroMetricChip(label: _formatDuration(metadata.durationMs)),
                  AstroMetricChip(label: '~${metadata.estimatedFrameCount} frames'),
                  AstroMetricChip(label: _formatSize(metadata.fileSizeBytes)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AstroWarningBox(
          message: 'Esse vídeo parece bom para processar. '
              '${metadata.estimatedFrameCount} frames estimados em ${_formatDuration(metadata.durationMs)}.',
        ),
        const SizedBox(height: 24),
        AstroButton(label: 'Continuar', icon: Icons.arrow_forward, onPressed: onContinue),
        const SizedBox(height: 8),
        Center(
          child: TextButton(onPressed: onChangeVideo, child: const Text('Trocar vídeo')),
        ),
      ],
    );
  }
}
