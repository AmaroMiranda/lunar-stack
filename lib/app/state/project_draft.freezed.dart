// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProjectDraft {
  VideoMetadata? get metadata => throw _privateConstructorUsedError;
  ProjectType? get projectType => throw _privateConstructorUsedError;
  StackConfig get stackConfig =>
      throw _privateConstructorUsedError; // Caminhos reais dos frames extraídos do vídeo (MediaMetadataRetriever).
  List<String> get framePaths => throw _privateConstructorUsedError;
  List<FrameQuality> get frameQualities => throw _privateConstructorUsedError;
  int? get suggestedPercent => throw _privateConstructorUsedError;
  String? get suggestionReason => throw _privateConstructorUsedError;
  ProcessingStage get stage => throw _privateConstructorUsedError;
  double get stageProgress => throw _privateConstructorUsedError;
  double get overallProgress => throw _privateConstructorUsedError;
  int get framesProcessed => throw _privateConstructorUsedError;
  int get framesTotal => throw _privateConstructorUsedError;
  StackResult? get stackResult =>
      throw _privateConstructorUsedError; // Caminho do frame usado como âncora de alinhamento — serve de "antes"
  // real no comparador da tela de Resultado.
  String? get referenceFramePath =>
      throw _privateConstructorUsedError; // Resultado do fluxo "Apenas estabilizar" (vídeo MP4 re-encodado).
  String? get stabilizedVideoPath => throw _privateConstructorUsedError;
  int get stabilizedWidth => throw _privateConstructorUsedError;
  int get stabilizedHeight => throw _privateConstructorUsedError;
  int get stabilizedFrames => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of ProjectDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectDraftCopyWith<ProjectDraft> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectDraftCopyWith<$Res> {
  factory $ProjectDraftCopyWith(
    ProjectDraft value,
    $Res Function(ProjectDraft) then,
  ) = _$ProjectDraftCopyWithImpl<$Res, ProjectDraft>;
  @useResult
  $Res call({
    VideoMetadata? metadata,
    ProjectType? projectType,
    StackConfig stackConfig,
    List<String> framePaths,
    List<FrameQuality> frameQualities,
    int? suggestedPercent,
    String? suggestionReason,
    ProcessingStage stage,
    double stageProgress,
    double overallProgress,
    int framesProcessed,
    int framesTotal,
    StackResult? stackResult,
    String? referenceFramePath,
    String? stabilizedVideoPath,
    int stabilizedWidth,
    int stabilizedHeight,
    int stabilizedFrames,
    String? errorMessage,
  });

  $VideoMetadataCopyWith<$Res>? get metadata;
  $StackConfigCopyWith<$Res> get stackConfig;
  $StackResultCopyWith<$Res>? get stackResult;
}

/// @nodoc
class _$ProjectDraftCopyWithImpl<$Res, $Val extends ProjectDraft>
    implements $ProjectDraftCopyWith<$Res> {
  _$ProjectDraftCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = freezed,
    Object? projectType = freezed,
    Object? stackConfig = null,
    Object? framePaths = null,
    Object? frameQualities = null,
    Object? suggestedPercent = freezed,
    Object? suggestionReason = freezed,
    Object? stage = null,
    Object? stageProgress = null,
    Object? overallProgress = null,
    Object? framesProcessed = null,
    Object? framesTotal = null,
    Object? stackResult = freezed,
    Object? referenceFramePath = freezed,
    Object? stabilizedVideoPath = freezed,
    Object? stabilizedWidth = null,
    Object? stabilizedHeight = null,
    Object? stabilizedFrames = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as VideoMetadata?,
            projectType: freezed == projectType
                ? _value.projectType
                : projectType // ignore: cast_nullable_to_non_nullable
                      as ProjectType?,
            stackConfig: null == stackConfig
                ? _value.stackConfig
                : stackConfig // ignore: cast_nullable_to_non_nullable
                      as StackConfig,
            framePaths: null == framePaths
                ? _value.framePaths
                : framePaths // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            frameQualities: null == frameQualities
                ? _value.frameQualities
                : frameQualities // ignore: cast_nullable_to_non_nullable
                      as List<FrameQuality>,
            suggestedPercent: freezed == suggestedPercent
                ? _value.suggestedPercent
                : suggestedPercent // ignore: cast_nullable_to_non_nullable
                      as int?,
            suggestionReason: freezed == suggestionReason
                ? _value.suggestionReason
                : suggestionReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            stage: null == stage
                ? _value.stage
                : stage // ignore: cast_nullable_to_non_nullable
                      as ProcessingStage,
            stageProgress: null == stageProgress
                ? _value.stageProgress
                : stageProgress // ignore: cast_nullable_to_non_nullable
                      as double,
            overallProgress: null == overallProgress
                ? _value.overallProgress
                : overallProgress // ignore: cast_nullable_to_non_nullable
                      as double,
            framesProcessed: null == framesProcessed
                ? _value.framesProcessed
                : framesProcessed // ignore: cast_nullable_to_non_nullable
                      as int,
            framesTotal: null == framesTotal
                ? _value.framesTotal
                : framesTotal // ignore: cast_nullable_to_non_nullable
                      as int,
            stackResult: freezed == stackResult
                ? _value.stackResult
                : stackResult // ignore: cast_nullable_to_non_nullable
                      as StackResult?,
            referenceFramePath: freezed == referenceFramePath
                ? _value.referenceFramePath
                : referenceFramePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            stabilizedVideoPath: freezed == stabilizedVideoPath
                ? _value.stabilizedVideoPath
                : stabilizedVideoPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            stabilizedWidth: null == stabilizedWidth
                ? _value.stabilizedWidth
                : stabilizedWidth // ignore: cast_nullable_to_non_nullable
                      as int,
            stabilizedHeight: null == stabilizedHeight
                ? _value.stabilizedHeight
                : stabilizedHeight // ignore: cast_nullable_to_non_nullable
                      as int,
            stabilizedFrames: null == stabilizedFrames
                ? _value.stabilizedFrames
                : stabilizedFrames // ignore: cast_nullable_to_non_nullable
                      as int,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of ProjectDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VideoMetadataCopyWith<$Res>? get metadata {
    if (_value.metadata == null) {
      return null;
    }

    return $VideoMetadataCopyWith<$Res>(_value.metadata!, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }

  /// Create a copy of ProjectDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StackConfigCopyWith<$Res> get stackConfig {
    return $StackConfigCopyWith<$Res>(_value.stackConfig, (value) {
      return _then(_value.copyWith(stackConfig: value) as $Val);
    });
  }

  /// Create a copy of ProjectDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StackResultCopyWith<$Res>? get stackResult {
    if (_value.stackResult == null) {
      return null;
    }

    return $StackResultCopyWith<$Res>(_value.stackResult!, (value) {
      return _then(_value.copyWith(stackResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectDraftImplCopyWith<$Res>
    implements $ProjectDraftCopyWith<$Res> {
  factory _$$ProjectDraftImplCopyWith(
    _$ProjectDraftImpl value,
    $Res Function(_$ProjectDraftImpl) then,
  ) = __$$ProjectDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    VideoMetadata? metadata,
    ProjectType? projectType,
    StackConfig stackConfig,
    List<String> framePaths,
    List<FrameQuality> frameQualities,
    int? suggestedPercent,
    String? suggestionReason,
    ProcessingStage stage,
    double stageProgress,
    double overallProgress,
    int framesProcessed,
    int framesTotal,
    StackResult? stackResult,
    String? referenceFramePath,
    String? stabilizedVideoPath,
    int stabilizedWidth,
    int stabilizedHeight,
    int stabilizedFrames,
    String? errorMessage,
  });

  @override
  $VideoMetadataCopyWith<$Res>? get metadata;
  @override
  $StackConfigCopyWith<$Res> get stackConfig;
  @override
  $StackResultCopyWith<$Res>? get stackResult;
}

/// @nodoc
class __$$ProjectDraftImplCopyWithImpl<$Res>
    extends _$ProjectDraftCopyWithImpl<$Res, _$ProjectDraftImpl>
    implements _$$ProjectDraftImplCopyWith<$Res> {
  __$$ProjectDraftImplCopyWithImpl(
    _$ProjectDraftImpl _value,
    $Res Function(_$ProjectDraftImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProjectDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = freezed,
    Object? projectType = freezed,
    Object? stackConfig = null,
    Object? framePaths = null,
    Object? frameQualities = null,
    Object? suggestedPercent = freezed,
    Object? suggestionReason = freezed,
    Object? stage = null,
    Object? stageProgress = null,
    Object? overallProgress = null,
    Object? framesProcessed = null,
    Object? framesTotal = null,
    Object? stackResult = freezed,
    Object? referenceFramePath = freezed,
    Object? stabilizedVideoPath = freezed,
    Object? stabilizedWidth = null,
    Object? stabilizedHeight = null,
    Object? stabilizedFrames = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$ProjectDraftImpl(
        metadata: freezed == metadata
            ? _value.metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as VideoMetadata?,
        projectType: freezed == projectType
            ? _value.projectType
            : projectType // ignore: cast_nullable_to_non_nullable
                  as ProjectType?,
        stackConfig: null == stackConfig
            ? _value.stackConfig
            : stackConfig // ignore: cast_nullable_to_non_nullable
                  as StackConfig,
        framePaths: null == framePaths
            ? _value._framePaths
            : framePaths // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        frameQualities: null == frameQualities
            ? _value._frameQualities
            : frameQualities // ignore: cast_nullable_to_non_nullable
                  as List<FrameQuality>,
        suggestedPercent: freezed == suggestedPercent
            ? _value.suggestedPercent
            : suggestedPercent // ignore: cast_nullable_to_non_nullable
                  as int?,
        suggestionReason: freezed == suggestionReason
            ? _value.suggestionReason
            : suggestionReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        stage: null == stage
            ? _value.stage
            : stage // ignore: cast_nullable_to_non_nullable
                  as ProcessingStage,
        stageProgress: null == stageProgress
            ? _value.stageProgress
            : stageProgress // ignore: cast_nullable_to_non_nullable
                  as double,
        overallProgress: null == overallProgress
            ? _value.overallProgress
            : overallProgress // ignore: cast_nullable_to_non_nullable
                  as double,
        framesProcessed: null == framesProcessed
            ? _value.framesProcessed
            : framesProcessed // ignore: cast_nullable_to_non_nullable
                  as int,
        framesTotal: null == framesTotal
            ? _value.framesTotal
            : framesTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        stackResult: freezed == stackResult
            ? _value.stackResult
            : stackResult // ignore: cast_nullable_to_non_nullable
                  as StackResult?,
        referenceFramePath: freezed == referenceFramePath
            ? _value.referenceFramePath
            : referenceFramePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        stabilizedVideoPath: freezed == stabilizedVideoPath
            ? _value.stabilizedVideoPath
            : stabilizedVideoPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        stabilizedWidth: null == stabilizedWidth
            ? _value.stabilizedWidth
            : stabilizedWidth // ignore: cast_nullable_to_non_nullable
                  as int,
        stabilizedHeight: null == stabilizedHeight
            ? _value.stabilizedHeight
            : stabilizedHeight // ignore: cast_nullable_to_non_nullable
                  as int,
        stabilizedFrames: null == stabilizedFrames
            ? _value.stabilizedFrames
            : stabilizedFrames // ignore: cast_nullable_to_non_nullable
                  as int,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ProjectDraftImpl implements _ProjectDraft {
  const _$ProjectDraftImpl({
    this.metadata,
    this.projectType,
    this.stackConfig = const StackConfig(),
    final List<String> framePaths = const [],
    final List<FrameQuality> frameQualities = const [],
    this.suggestedPercent,
    this.suggestionReason,
    this.stage = ProcessingStage.idle,
    this.stageProgress = 0.0,
    this.overallProgress = 0.0,
    this.framesProcessed = 0,
    this.framesTotal = 0,
    this.stackResult,
    this.referenceFramePath,
    this.stabilizedVideoPath,
    this.stabilizedWidth = 0,
    this.stabilizedHeight = 0,
    this.stabilizedFrames = 0,
    this.errorMessage,
  }) : _framePaths = framePaths,
       _frameQualities = frameQualities;

  @override
  final VideoMetadata? metadata;
  @override
  final ProjectType? projectType;
  @override
  @JsonKey()
  final StackConfig stackConfig;
  // Caminhos reais dos frames extraídos do vídeo (MediaMetadataRetriever).
  final List<String> _framePaths;
  // Caminhos reais dos frames extraídos do vídeo (MediaMetadataRetriever).
  @override
  @JsonKey()
  List<String> get framePaths {
    if (_framePaths is EqualUnmodifiableListView) return _framePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_framePaths);
  }

  final List<FrameQuality> _frameQualities;
  @override
  @JsonKey()
  List<FrameQuality> get frameQualities {
    if (_frameQualities is EqualUnmodifiableListView) return _frameQualities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frameQualities);
  }

  @override
  final int? suggestedPercent;
  @override
  final String? suggestionReason;
  @override
  @JsonKey()
  final ProcessingStage stage;
  @override
  @JsonKey()
  final double stageProgress;
  @override
  @JsonKey()
  final double overallProgress;
  @override
  @JsonKey()
  final int framesProcessed;
  @override
  @JsonKey()
  final int framesTotal;
  @override
  final StackResult? stackResult;
  // Caminho do frame usado como âncora de alinhamento — serve de "antes"
  // real no comparador da tela de Resultado.
  @override
  final String? referenceFramePath;
  // Resultado do fluxo "Apenas estabilizar" (vídeo MP4 re-encodado).
  @override
  final String? stabilizedVideoPath;
  @override
  @JsonKey()
  final int stabilizedWidth;
  @override
  @JsonKey()
  final int stabilizedHeight;
  @override
  @JsonKey()
  final int stabilizedFrames;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'ProjectDraft(metadata: $metadata, projectType: $projectType, stackConfig: $stackConfig, framePaths: $framePaths, frameQualities: $frameQualities, suggestedPercent: $suggestedPercent, suggestionReason: $suggestionReason, stage: $stage, stageProgress: $stageProgress, overallProgress: $overallProgress, framesProcessed: $framesProcessed, framesTotal: $framesTotal, stackResult: $stackResult, referenceFramePath: $referenceFramePath, stabilizedVideoPath: $stabilizedVideoPath, stabilizedWidth: $stabilizedWidth, stabilizedHeight: $stabilizedHeight, stabilizedFrames: $stabilizedFrames, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectDraftImpl &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.projectType, projectType) ||
                other.projectType == projectType) &&
            (identical(other.stackConfig, stackConfig) ||
                other.stackConfig == stackConfig) &&
            const DeepCollectionEquality().equals(
              other._framePaths,
              _framePaths,
            ) &&
            const DeepCollectionEquality().equals(
              other._frameQualities,
              _frameQualities,
            ) &&
            (identical(other.suggestedPercent, suggestedPercent) ||
                other.suggestedPercent == suggestedPercent) &&
            (identical(other.suggestionReason, suggestionReason) ||
                other.suggestionReason == suggestionReason) &&
            (identical(other.stage, stage) || other.stage == stage) &&
            (identical(other.stageProgress, stageProgress) ||
                other.stageProgress == stageProgress) &&
            (identical(other.overallProgress, overallProgress) ||
                other.overallProgress == overallProgress) &&
            (identical(other.framesProcessed, framesProcessed) ||
                other.framesProcessed == framesProcessed) &&
            (identical(other.framesTotal, framesTotal) ||
                other.framesTotal == framesTotal) &&
            (identical(other.stackResult, stackResult) ||
                other.stackResult == stackResult) &&
            (identical(other.referenceFramePath, referenceFramePath) ||
                other.referenceFramePath == referenceFramePath) &&
            (identical(other.stabilizedVideoPath, stabilizedVideoPath) ||
                other.stabilizedVideoPath == stabilizedVideoPath) &&
            (identical(other.stabilizedWidth, stabilizedWidth) ||
                other.stabilizedWidth == stabilizedWidth) &&
            (identical(other.stabilizedHeight, stabilizedHeight) ||
                other.stabilizedHeight == stabilizedHeight) &&
            (identical(other.stabilizedFrames, stabilizedFrames) ||
                other.stabilizedFrames == stabilizedFrames) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    metadata,
    projectType,
    stackConfig,
    const DeepCollectionEquality().hash(_framePaths),
    const DeepCollectionEquality().hash(_frameQualities),
    suggestedPercent,
    suggestionReason,
    stage,
    stageProgress,
    overallProgress,
    framesProcessed,
    framesTotal,
    stackResult,
    referenceFramePath,
    stabilizedVideoPath,
    stabilizedWidth,
    stabilizedHeight,
    stabilizedFrames,
    errorMessage,
  ]);

  /// Create a copy of ProjectDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectDraftImplCopyWith<_$ProjectDraftImpl> get copyWith =>
      __$$ProjectDraftImplCopyWithImpl<_$ProjectDraftImpl>(this, _$identity);
}

abstract class _ProjectDraft implements ProjectDraft {
  const factory _ProjectDraft({
    final VideoMetadata? metadata,
    final ProjectType? projectType,
    final StackConfig stackConfig,
    final List<String> framePaths,
    final List<FrameQuality> frameQualities,
    final int? suggestedPercent,
    final String? suggestionReason,
    final ProcessingStage stage,
    final double stageProgress,
    final double overallProgress,
    final int framesProcessed,
    final int framesTotal,
    final StackResult? stackResult,
    final String? referenceFramePath,
    final String? stabilizedVideoPath,
    final int stabilizedWidth,
    final int stabilizedHeight,
    final int stabilizedFrames,
    final String? errorMessage,
  }) = _$ProjectDraftImpl;

  @override
  VideoMetadata? get metadata;
  @override
  ProjectType? get projectType;
  @override
  StackConfig get stackConfig; // Caminhos reais dos frames extraídos do vídeo (MediaMetadataRetriever).
  @override
  List<String> get framePaths;
  @override
  List<FrameQuality> get frameQualities;
  @override
  int? get suggestedPercent;
  @override
  String? get suggestionReason;
  @override
  ProcessingStage get stage;
  @override
  double get stageProgress;
  @override
  double get overallProgress;
  @override
  int get framesProcessed;
  @override
  int get framesTotal;
  @override
  StackResult? get stackResult; // Caminho do frame usado como âncora de alinhamento — serve de "antes"
  // real no comparador da tela de Resultado.
  @override
  String? get referenceFramePath; // Resultado do fluxo "Apenas estabilizar" (vídeo MP4 re-encodado).
  @override
  String? get stabilizedVideoPath;
  @override
  int get stabilizedWidth;
  @override
  int get stabilizedHeight;
  @override
  int get stabilizedFrames;
  @override
  String? get errorMessage;

  /// Create a copy of ProjectDraft
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectDraftImplCopyWith<_$ProjectDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
