import 'dart:math';

import '../../../core/domain/frame_quality.dart';

/// Suggests what percentage of frames to keep for stacking, based on the
/// spread (std-dev) of the real per-frame quality scores: a video with a lot
/// of variance has shaky/blurry stretches, so a smaller, stricter selection
/// produces a sharper stack (spec section 6.5).
({int percent, String reason}) suggestFrameSelectionPercent(List<FrameQuality> frames) {
  if (frames.isEmpty) return (percent: 25, reason: 'Sem dados suficientes.');

  final scores = frames.map((f) => f.qualityScore).toList()..sort();
  final mean = scores.reduce((a, b) => a + b) / scores.length;
  final variance = scores.map((s) => pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
  final stdDev = sqrt(variance);

  // Lucky-imaging principle, confirmed by measuring a real clip: empilhar
  // frames demais (mesmo num vídeo estável) suaviza o detalhe fino — cada
  // frame um pouco menos nítido puxa o resultado pra baixo. Empilhar só o
  // terço/quarto mais nítido retém bem mais detalhe e ainda reduz ruído o
  // suficiente (a Lua é brilhante, então ruído incomoda menos que borrão).
  if (stdDev > 0.22) {
    return (
      percent: 10,
      reason: 'Muitos frames apresentam tremor ou perda de nitidez. Uma seleção pequena (10%) gera bem mais nitidez.',
    );
  } else if (stdDev > 0.12) {
    return (
      percent: 20,
      reason: 'O vídeo tem alguns trechos instáveis. Os melhores 20% devem ficar mais nítidos.',
    );
  } else {
    return (
      percent: 33,
      reason: 'O vídeo está bastante estável. Ainda assim, usar só o terço mais nítido preserva mais detalhe do que empilhar todos os frames.',
    );
  }
}
