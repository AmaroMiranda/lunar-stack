import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/frame_quality.dart';

/// Gráfico de qualidade por frame (spec seção 35.5) — linha + destaque da
/// faixa selecionada, para o usuário enxergar por que a sugestão foi feita.
class AstroQualityGraph extends StatelessWidget {
  const AstroQualityGraph({
    super.key,
    required this.frames,
    required this.thresholdScore,
  });

  final List<FrameQuality> frames;
  final double thresholdScore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (frames.isEmpty) return const SizedBox.shrink();

    final spots = [
      for (final f in frames) FlSpot(f.frameIndex.toDouble(), f.qualityScore),
    ];

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: thresholdScore,
              color: scheme.tertiary,
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
          ]),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.15,
              color: scheme.secondary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.secondary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
