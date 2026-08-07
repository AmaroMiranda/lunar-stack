import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Selo discreto de "atualizando prévia" no canto de um preview de edição
/// (Lua Mineral, wavelets). Fica sobre a imagem em preto, sem roubar atenção.
class RenderingBadge extends StatelessWidget {
  const RenderingBadge({super.key, this.label = 'atualizando'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: monoStyle(size: 11, color: Colors.white.withValues(alpha: 0.85))),
          ],
        ),
      ),
    );
  }
}
