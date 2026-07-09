import 'package:freezed_annotation/freezed_annotation.dart';

part 'stabilized_video_result.freezed.dart';

@freezed
class StabilizedVideoResult with _$StabilizedVideoResult {
  const factory StabilizedVideoResult({
    required String outputPath,
    required int width,
    required int height,
    required int durationMs,
    required int framesProcessed,
    required bool cropApplied,
    required int processingTimeMs,
  }) = _StabilizedVideoResult;
}
