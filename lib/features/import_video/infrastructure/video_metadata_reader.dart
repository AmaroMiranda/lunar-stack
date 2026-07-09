import 'package:video_player/video_player.dart';

import '../../../core/domain/video_metadata.dart';

/// video_player não expõe FPS/contagem de frames real — assumimos 30fps como
/// estimativa (rotulada como tal na UI) até o engine nativo decodificar de
/// verdade.
const kEstimatedFps = 30.0;

VideoMetadata buildMetadataFromController({
  required String uri,
  required String fileName,
  required int fileSizeBytes,
  required VideoPlayerController controller,
}) {
  final durationMs = controller.value.duration.inMilliseconds;
  final size = controller.value.size;
  final estimatedFrameCount = ((durationMs / 1000) * kEstimatedFps).round();

  return VideoMetadata(
    uri: uri,
    fileName: fileName,
    durationMs: durationMs,
    width: size.width.round(),
    height: size.height.round(),
    fps: kEstimatedFps,
    estimatedFrameCount: estimatedFrameCount,
    fileSizeBytes: fileSizeBytes,
  );
}
