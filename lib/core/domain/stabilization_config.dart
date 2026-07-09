import 'package:freezed_annotation/freezed_annotation.dart';

part 'stabilization_config.freezed.dart';

enum SmoothingLevel { low, medium, high }

enum OutputResolutionMode { original, croppedSmaller }

@freezed
class StabilizationConfig with _$StabilizationConfig {
  const factory StabilizationConfig({
    @Default(true) bool enabled,
    @Default(true) bool centerObject,
    @Default(true) bool cropAutomatic,
    @Default(0.2) double marginPercent,
    @Default(SmoothingLevel.medium) SmoothingLevel smoothing,
    @Default(OutputResolutionMode.croppedSmaller)
    OutputResolutionMode outputResolutionMode,
    @Default(true) bool exportVideo,
  }) = _StabilizationConfig;
}

@freezed
class StabilizationFrameData with _$StabilizationFrameData {
  const factory StabilizationFrameData({
    required int frameIndex,
    required int timestampMs,
    required bool detected,
    required double centerX,
    required double centerY,
    required double shiftX,
    required double shiftY,
    required double confidence,
  }) = _StabilizationFrameData;
}
