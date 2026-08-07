import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Rótulo curto de seção — caixa-alta com letter-spacing, cor discreta.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: LunarColors.mist500),
    );
  }
}
