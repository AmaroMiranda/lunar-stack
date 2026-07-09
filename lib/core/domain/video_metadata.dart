import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_metadata.freezed.dart';

@freezed
class VideoMetadata with _$VideoMetadata {
  const factory VideoMetadata({
    required String uri,
    required String fileName,
    required int durationMs,
    required int width,
    required int height,
    required double fps,
    required int estimatedFrameCount,
    required int fileSizeBytes,
    String? codec,
  }) = _VideoMetadata;
}
