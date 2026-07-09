import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/processing_stage.dart';
import '../../../core/domain/project_type.dart';
import '../../../core/widgets/astro_card.dart';
import '../application/history_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projetos recentes')),
      body: SafeArea(
        child: history.when(
          data: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Nenhum projeto ainda. Importe um vídeo da Lua para começar seu primeiro processamento.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = entries[i];
                return AstroCard(
                  child: Row(
                    children: [
                      Icon(
                        e.status == ProcessingStage.done ? Icons.check_circle : Icons.error_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.name, style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              '${e.projectType.title} · ${e.summary}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(e.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Não consegui carregar o histórico.')),
        ),
      ),
    );
  }
}
