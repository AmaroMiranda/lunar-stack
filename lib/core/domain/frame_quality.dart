import 'package:freezed_annotation/freezed_annotation.dart';

part 'frame_quality.freezed.dart';

@freezed
class FrameQuality with _$FrameQuality {
  const factory FrameQuality({
    required int frameIndex,
    required int timestampMs,
    required double qualityScore,
    required double sharpnessScore,
    required double contrastScore,
    required double exposurePenalty,
    required double stabilizationConfidence,
  }) = _FrameQuality;
}
