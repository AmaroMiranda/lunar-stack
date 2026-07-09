import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum AstroWarningSeverity { info, warning }

/// Caixa de aviso honesta sobre limitações (spec seção 43): texto + ícone,
/// nunca depende só de cor para passar a informação.
class AstroWarningBox extends StatelessWidget {
  const AstroWarningBox({
    super.key,
    required this.message,
    this.severity = AstroWarningSeverity.info,
  });

  final String message;
  final AstroWarningSeverity severity;

  @override
  Widget build(BuildContext context) {
    final isWarning = severity == AstroWarningSeverity.warning;
    final color = isWarning ? LunarColors.warningOrange : Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isWarning ? Icons.warning_amber_rounded : Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
