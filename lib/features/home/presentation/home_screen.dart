import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/processing_stage.dart';
import '../../../core/domain/project_type.dart';
import '../../../core/widgets/astro_card.dart';
import '../../history/application/history_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('LunarStack', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Estabilize e empilhe vídeos da Lua direto no Android.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _HomeActionCard(
              icon: Icons.center_focus_strong,
              title: 'Estabilizar vídeo',
              description: 'Centralize a Lua e reduza tremores.',
              onTap: () => context.push('/import'),
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              icon: Icons.auto_awesome,
              title: 'Empilhar imagem',
              description: 'Use os melhores frames para gerar uma foto mais limpa.',
              onTap: () => context.push('/import'),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Projetos recentes', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            history.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return AstroCard(
                    child: Text(
                      'Nenhum projeto ainda. Importe um vídeo da Lua para começar seu primeiro processamento.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return Column(
                  children: entries
                      .take(3)
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AstroCard(
                              child: Row(
                                children: [
                                  Icon(
                                    e.status == ProcessingStage.done
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.name, style: Theme.of(context).textTheme.titleMedium),
                                        Text(
                                          '${e.projectType.title} · ${DateFormat('dd/MM/yyyy HH:mm').format(e.createdAt)}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Text(
              'Dica: use vídeos curtos e estáveis para melhores resultados.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AstroCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.outline),
        ],
      ),
    );
  }
}
