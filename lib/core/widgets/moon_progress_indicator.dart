import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Indicador de progresso temático: um disco lunar que se enche de luz da
/// esquerda para a direita conforme o processamento avança, com um arco
/// orbit-blue ao redor. Substitui a barra linear genérica na tela de
/// processamento — o "esperar" vira um elemento próprio (Observatory Dark).
class MoonProgressIndicator extends StatelessWidget {
  const MoonProgressIndicator({
    super.key,
    required this.progress,
    this.size = 188,
  });

  /// 0..1. Fora desse intervalo é fixado (o motor às vezes reporta &gt;1).
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoonProgressPainter(p),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(p * 100).toStringAsFixed(0)}%',
                style: monoStyle(
                  size: size * 0.2,
                  color: LunarColors.mist100,
                  weight: FontWeight.w700,
                ).copyWith(
                  // O número cruza a linha entre a metade clara e a escura da
                  // Lua; um contorno escuro garante leitura nos dois lados.
                  shadows: const [
                    Shadow(color: Color(0xEE05070D), blurRadius: 5),
                    Shadow(color: Color(0xEE05070D), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoonProgressPainter extends CustomPainter {
  _MoonProgressPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2;
    const ringStroke = 6.0;
    final ringR = outerR - ringStroke / 2;
    final discR = outerR - ringStroke - 10;

    // Halo suave atrás do disco.
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          LunarColors.orbitBlue.withValues(alpha: 0.22),
          LunarColors.orbitBlue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: discR * 1.35));
    canvas.drawCircle(center, discR * 1.35, haloPaint);

    // Disco lunar apagado (base).
    canvas.drawCircle(
      center,
      discR,
      Paint()..color = const Color(0xFF1B2536),
    );

    // Porção iluminada: varredura da esquerda até `progress`.
    if (progress > 0) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: discR)));
      final litWidth = discR * 2 * progress;
      final litRect = Rect.fromLTWH(
        center.dx - discR,
        center.dy - discR,
        litWidth,
        discR * 2,
      );
      canvas.drawRect(litRect, Paint()..color = LunarColors.lunarPearl);

      // Crateras sutis só na parte iluminada, para dar textura de Lua.
      final crater = Paint()..color = const Color(0x22141C2B);
      void drawCrater(double dx, double dy, double r) {
        final c = center + Offset(dx * discR, dy * discR);
        if (c.dx <= center.dx - discR + litWidth) {
          canvas.drawCircle(c, r * discR, crater);
        }
      }

      drawCrater(-0.35, -0.28, 0.14);
      drawCrater(0.18, 0.30, 0.18);
      drawCrater(-0.10, 0.42, 0.08);
      drawCrater(0.40, -0.35, 0.10);
      canvas.restore();
    }

    // Anel de trilho (apagado).
    canvas.drawCircle(
      center,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringStroke
        ..color = LunarColors.border,
    );

    // Arco de progresso, começando no topo (−90°), horário.
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringR),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringStroke
        ..strokeCap = StrokeCap.round
        ..color = LunarColors.orbitBlue,
    );
  }

  @override
  bool shouldRepaint(covariant _MoonProgressPainter old) => old.progress != progress;
}
