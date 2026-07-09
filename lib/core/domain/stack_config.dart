import 'package:freezed_annotation/freezed_annotation.dart';

part 'stack_config.freezed.dart';

enum StackingMethod { simpleAverage, weightedAverage }

enum AlignmentMethod { globalPhaseCorrelation }

enum OutputFormat { png, jpeg, tiff }

extension OutputFormatInfo on OutputFormat {
  String get extension => switch (this) {
        OutputFormat.png => 'png',
        OutputFormat.jpeg => 'jpg',
        OutputFormat.tiff => 'tif',
      };

  String get label => switch (this) {
        OutputFormat.png => 'PNG',
        OutputFormat.jpeg => 'JPEG',
        OutputFormat.tiff => 'TIFF 16-bit',
      };
}

extension StackingMethodLabel on StackingMethod {
  String get label => switch (this) {
        StackingMethod.simpleAverage => 'Média simples',
        StackingMethod.weightedAverage => 'Média ponderada',
      };
}

@freezed
class StackConfig with _$StackConfig {
  const factory StackConfig({
    @Default(25) int frameSelectionPercent,
    @Default(500) int maxFrames,
    @Default(StackingMethod.weightedAverage) StackingMethod stackingMethod,
    @Default(AlignmentMethod.globalPhaseCorrelation)
    AlignmentMethod alignmentMethod,
    @Default(true) bool useStabilizationData,
    @Default(true) bool sharpenMode,
    // Empilhamento cru: só alinhar e tirar a média — nenhum ajuste de
    // nitidez/tom na imagem final. Tem precedência sobre [sharpenMode].
    @Default(false) bool rawMode,
    @Default(true) bool autoCropEnabled,
    @Default(OutputFormat.png) OutputFormat outputFormat,
  }) = _StackConfig;
}
