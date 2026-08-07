import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/project_tile.dart';
import '../../../core/widgets/section_label.dart';
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
                    'Nenhum projeto ainda. Importe um vídeo ou fotos da Lua para começar seu primeiro processamento.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: entries.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: SectionLabel('Todos os projetos'),
                  );
                }
                return ProjectTile(entry: entries[i - 1], showSummary: true);
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
