import 'package:freezed_annotation/freezed_annotation.dart';

import 'stack_config.dart';

part 'stack_result.freezed.dart';

@freezed
class StackResult with _$StackResult {
  const factory StackResult({
    required String outputPath,
    required String previewPath,
    required int width,
    required int height,
    required int framesAnalyzed,
    required int framesStacked,
    required int processingTimeMs,
    required StackingMethod stackingMethod,
    required AlignmentMethod alignmentMethod,
  }) = _StackResult;
}
