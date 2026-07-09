import 'package:flutter/material.dart';

/// Mostra etapa atual + mensagem explicativa (spec seção 35.7) —
/// nunca "Processando..." genérico.
class AstroProgressCard extends StatelessWidget {
  const AstroProgressCard({
    super.key,
    required this.stageLabel,
    required this.message,
    required this.progress,
    this.detail,
  });

  final String stageLabel;
  final String message;
  final double progress;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stageLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (detail != null)
                  Text(detail!, style: Theme.of(context).textTheme.bodySmall)
                else
                  const SizedBox.shrink(),
                Text(
                  '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.secondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
