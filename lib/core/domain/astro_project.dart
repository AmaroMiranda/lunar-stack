import 'package:freezed_annotation/freezed_annotation.dart';

import 'processing_stage.dart';
import 'project_type.dart';
import 'stabilization_config.dart';
import 'stack_config.dart';
import 'video_metadata.dart';

part 'astro_project.freezed.dart';

@freezed
class AstroProject with _$AstroProject {
  const factory AstroProject({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String sourceVideoUri,
    String? thumbnailPath,
    required ProjectType projectType,
    @Default(ProcessingStage.idle) ProcessingStage status,
    String? resultImagePath,
    String? stabilizedVideoPath,
    StabilizationConfig? stabilizationConfig,
    StackConfig? stackConfig,
    VideoMetadata? metadata,
  }) = _AstroProject;
}
