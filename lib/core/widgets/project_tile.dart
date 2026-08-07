import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../features/history/domain/history_entry.dart';
import '../domain/processing_stage.dart';
import '../domain/project_type.dart';
import 'astro_card.dart';

/// Card de projeto usado na home ("Projetos recentes") e no histórico —
/// mesmo desenho nos dois lugares. Concluído = marca verde; caso contrário,
/// aviso âmbar. Toque reabre o resultado salvo quando disponível.
class ProjectTile extends StatelessWidget {
  const ProjectTile({
    super.key,
    required this.entry,
    this.showSummary = false,
  });

  final HistoryEntry entry;

  /// No histórico mostramos também o resumo (frames · método); na home,
  /// só o tipo e a data, para o card ficar mais enxuto.
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    final done = entry.status == ProcessingStage.done;
    final canReopen = done && entry.resultPath != null;
    final accent = done ? LunarColors.success : LunarColors.warning;
    final date = DateFormat('dd/MM · HH:mm').format(entry.createdAt);
    final subtitle = showSummary
        ? '${entry.projectType.title} · ${entry.summary} · $date'
        : '${entry.projectType.title} · $date';

    return AstroCard(
      onTap: canReopen ? () => context.push('/history-view', extra: entry) : null,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.error_outline,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canReopen)
            const Icon(Icons.chevron_right, color: LunarColors.mist500),
        ],
      ),
    );
  }
}
