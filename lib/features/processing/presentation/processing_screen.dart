import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/domain/processing_stage.dart';
import '../../../core/domain/project_type.dart';
import '../../../core/widgets/astro_progress_card.dart';
import '../../../core/widgets/astro_warning_box.dart';

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
              _ => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AstroProgressCard(
                        stageLabel: draft.stage.shortLabel,
                        message: draft.stage.label,
                        progress: draft.overallProgress,
                        detail: '${draft.framesProcessed}/$totalFrames frames',
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () => ref.read(projectDraftProvider.notifier).cancelProcessing(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  ),
            },
          ),
        ),
      ),
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
