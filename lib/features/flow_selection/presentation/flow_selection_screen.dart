import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/domain/project_type.dart';
import '../../../core/widgets/astro_card.dart';

// Todos os fluxos rodam de verdade: empilhar via engine nativo, estabilizar
// via MediaCodec/MediaMuxer, e o combinado = extração com a Lua
// pré-centralizada (shift inteiro, sem re-encode) + empilhamento normal.
const _kAvailableTypes = {
  ProjectType.stacking,
  ProjectType.stabilization,
  ProjectType.stabilizationPlusStacking,
};

class FlowSelectionScreen extends ConsumerWidget {
  const FlowSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(
          projectDraftProvider.select((d) => d.projectType),
        ) ??
        ProjectType.stacking;

    return Scaffold(
      appBar: AppBar(title: const Text('Escolha o fluxo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('O que você quer fazer com esse vídeo?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              for (final type in ProjectType.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FlowOptionCard(
                    type: type,
                    selected: type == selectedType,
                    available: _kAvailableTypes.contains(type),
                    onTap: () =>
                        ref.read(projectDraftProvider.notifier).setProjectType(type),
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  ref.read(projectDraftProvider.notifier).setProjectType(selectedType);
                  // Empilhar passa pela análise de nitidez; estabilizar vai
                  // direto pro processamento (o pipeline é um passe só).
                  context.push(
                    selectedType == ProjectType.stabilization ? '/processing' : '/analysis',
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowOptionCard extends StatelessWidget {
  const _FlowOptionCard({
    required this.type,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final ProjectType type;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: available ? 1.0 : 0.5,
      child: AstroCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              available
                  ? (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked)
                  : Icons.lock_outline,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          type.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (available ? scheme.tertiary : scheme.outline).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          available ? 'Disponível' : 'Em breve',
                          style: TextStyle(
                            color: available ? scheme.tertiary : scheme.outline,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(type.description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
