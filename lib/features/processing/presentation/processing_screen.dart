import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../app/theme.dart';
import '../../../core/domain/processing_stage.dart';
import '../../../core/domain/project_type.dart';
import '../../../core/widgets/astro_warning_box.dart';
import '../../../core/widgets/moon_progress_indicator.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_started) return;
      _started = true;
      ref.read(projectDraftProvider.notifier).runProcessing().then((_) {
        final draft = ref.read(projectDraftProvider);
        if (mounted && draft.stage == ProcessingStage.done) {
          context.go(
            draft.projectType == ProjectType.stabilization ? '/result-video' : '/result',
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(projectDraftProvider);
    final totalFrames = draft.framesTotal;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Processando'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: switch (draft.stage) {
              ProcessingStage.cancelled => _CancelledState(onBack: () => context.go('/')),
              ProcessingStage.failed => _FailedState(
                  message: draft.errorMessage ?? 'Algo deu errado durante o processamento.',
                  onBack: () => context.go('/'),
                ),
              _ => _RunningState(
                    stageLabel: draft.stage.shortLabel,
                    message: draft.stage.label,
                    progress: draft.overallProgress,
                    detail: totalFrames > 0
                        ? '${draft.framesProcessed}/$totalFrames frames'
                        : null,
                    onCancel: () =>
                        ref.read(projectDraftProvider.notifier).cancelProcessing(),
                  ),
            },
          ),
        ),
      ),
    );
  }
}

/// Composição estática do estado "processando" — usada só pelo golden test
/// para validar o visual sem depender do motor/Riverpod.
class ProcessingPreview extends StatelessWidget {
  const ProcessingPreview({super.key, this.progress = 0.62});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processando'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _RunningState(
            stageLabel: 'Empilhando frames',
            message: 'Alinhando e combinando os 214 melhores frames em uma '
                'única imagem nítida.',
            progress: progress,
            detail: '133/214 frames',
            onCancel: () {},
          ),
        ),
      ),
    );
  }
}

class _RunningState extends StatelessWidget {
  const _RunningState({
    required this.stageLabel,
    required this.message,
    required this.progress,
    required this.onCancel,
    this.detail,
  });

  final String stageLabel;
  final String message;
  final double progress;
  final String? detail;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        MoonProgressIndicator(progress: progress),
        const SizedBox(height: 32),
        Text(
          stageLabel,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 14),
          Text(detail!, style: monoStyle(size: 13, color: LunarColors.mist500)),
        ],
        const Spacer(flex: 3),
        OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Cancelar'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CancelledState extends StatelessWidget {
  const _CancelledState({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Processamento cancelado.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FilledButton(onPressed: onBack, child: const Text('Voltar para o início')),
        ],
      ),
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState({required this.message, required this.onBack});
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AstroWarningBox(message: message, severity: AstroWarningSeverity.warning),
          const SizedBox(height: 20),
          FilledButton(onPressed: onBack, child: const Text('Voltar para o início')),
        ],
      ),
    );
  }
}
