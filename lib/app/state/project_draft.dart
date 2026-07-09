import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/domain/frame_quality.dart';
import '../../core/domain/processing_stage.dart';
import '../../core/domain/project_type.dart';
import '../../core/domain/stack_config.dart';
import '../../core/domain/stack_result.dart';
import '../../core/domain/video_metadata.dart';

part 'project_draft.freezed.dart';

/// Estado do assistente (import → fluxo → config → processamento →
/// resultado) que precisa atravessar várias telas da navegação.
@freezed
class ProjectDraft with _$ProjectDraft {
  const factory ProjectDraft({
    VideoMetadata? metadata,
    ProjectType? projectType,
    @Default(StackConfig()) StackConfig stackConfig,
    // Caminhos reais dos frames extraídos do vídeo (MediaMetadataRetriever).
    @Default([]) List<String> framePaths,
    @Default([]) List<FrameQuality> frameQualities,
    int? suggestedPercent,
    String? suggestionReason,
    @Default(ProcessingStage.idle) ProcessingStage stage,
    @Default(0.0) double stageProgress,
    @Default(0.0) double overallProgress,
    @Default(0) int framesProcessed,
    @Default(0) int framesTotal,
    StackResult? stackResult,
    // Caminho do frame usado como âncora de alinhamento — serve de "antes"
    // real no comparador da tela de Resultado.
    String? referenceFramePath,
    // Resultado do fluxo "Apenas estabilizar" (vídeo MP4 re-encodado).
    String? stabilizedVideoPath,
    @Default(0) int stabilizedWidth,
    @Default(0) int stabilizedHeight,
    @Default(0) int stabilizedFrames,
    String? errorMessage,
  }) = _ProjectDraft;
}
