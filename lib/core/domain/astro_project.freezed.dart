// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'astro_project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AstroProject {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String get sourceVideoUri => throw _privateConstructorUsedError;
  String? get thumbnailPath => throw _privateConstructorUsedError;
  ProjectType get projectType => throw _privateConstructorUsedError;
  ProcessingStage get status => throw _privateConstructorUsedError;
  String? get resultImagePath => throw _privateConstructorUsedError;
  String? get stabilizedVideoPath => throw _privateConstructorUsedError;
  StabilizationConfig? get stabilizationConfig =>
      throw _privateConstructorUsedError;
  StackConfig? get stackConfig => throw _privateConstructorUsedError;
  VideoMetadata? get metadata => throw _privateConstructorUsedError;

  /// Create a copy of AstroProject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AstroProjectCopyWith<AstroProject> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AstroProjectCopyWith<$Res> {
  factory $AstroProjectCopyWith(
    AstroProject value,
    $Res Function(AstroProject) then,
  ) = _$AstroProjectCopyWithImpl<$Res, AstroProject>;
  @useResult
  $Res call({
    String id,
    String name,
    DateTime createdAt,
    DateTime updatedAt,
    String sourceVideoUri,
    String? thumbnailPath,
    ProjectType projectType,
    ProcessingStage status,
    String? resultImagePath,
    String? stabilizedVideoPath,
    StabilizationConfig? stabilizationConfig,
    StackConfig? stackConfig,
    VideoMetadata? metadata,
  });

  $StabilizationConfigCopyWith<$Res>? get stabilizationConfig;
  $StackConfigCopyWith<$Res>? get stackConfig;
  $VideoMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class _$AstroProjectCopyWithImpl<$Res, $Val extends AstroProject>
    implements $AstroProjectCopyWith<$Res> {
  _$AstroProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AstroProject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? sourceVideoUri = null,
    Object? thumbnailPath = freezed,
    Object? projectType = null,
    Object? status = null,
    Object? resultImagePath = freezed,
    Object? stabilizedVideoPath = freezed,
    Object? stabilizationConfig = freezed,
    Object? stackConfig = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            sourceVideoUri: null == sourceVideoUri
                ? _value.sourceVideoUri
                : sourceVideoUri // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbnailPath: freezed == thumbnailPath
                ? _value.thumbnailPath
                : thumbnailPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectType: null == projectType
                ? _value.projectType
                : projectType // ignore: cast_nullable_to_non_nullable
                      as ProjectType,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ProcessingStage,
            resultImagePath: freezed == resultImagePath
                ? _value.resultImagePath
                : resultImagePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            stabilizedVideoPath: freezed == stabilizedVideoPath
                ? _value.stabilizedVideoPath
                : stabilizedVideoPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            stabilizationConfig: freezed == stabilizationConfig
                ? _value.stabilizationConfig
                : stabilizationConfig // ignore: cast_nullable_to_non_nullable
                      as StabilizationConfig?,
            stackConfig: freezed == stackConfig
                ? _value.stackConfig
                : stackConfig // ignore: cast_nullable_to_non_nullable
                      as StackConfig?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as VideoMetadata?,
          )
          as $Val,
    );
  }

  /// Create a copy of AstroProject
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StabilizationConfigCopyWith<$Res>? get stabilizationConfig {
    if (_value.stabilizationConfig == null) {
      return null;
    }

    return $StabilizationConfigCopyWith<$Res>(_value.stabilizationConfig!, (
      value,
    ) {
      return _then(_value.copyWith(stabilizationConfig: value) as $Val);
    });
  }

  /// Create a copy of AstroProject
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StackConfigCopyWith<$Res>? get stackConfig {
    if (_value.stackConfig == null) {
      return null;
    }

    return $StackConfigCopyWith<$Res>(_value.stackConfig!, (value) {
      return _then(_value.copyWith(stackConfig: value) as $Val);
    });
  }

  /// Create a copy of AstroProject
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
}

/// @nodoc
abstract class _$$AstroProjectImplCopyWith<$Res>
    implements $AstroProjectCopyWith<$Res> {
  factory _$$AstroProjectImplCopyWith(
    _$AstroProjectImpl value,
    $Res Function(_$AstroProjectImpl) then,
  ) = __$$AstroProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    DateTime createdAt,
    DateTime updatedAt,
    String sourceVideoUri,
    String? thumbnailPath,
    ProjectType projectType,
    ProcessingStage status,
    String? resultImagePath,
    String? stabilizedVideoPath,
    StabilizationConfig? stabilizationConfig,
    StackConfig? stackConfig,
    VideoMetadata? metadata,
  });

  @override
  $StabilizationConfigCopyWith<$Res>? get stabilizationConfig;
  @override
  $StackConfigCopyWith<$Res>? get stackConfig;
  @override
  $VideoMetadataCopyWith<$Res>? get metadata;
}

/// @nodoc
class __$$AstroProjectImplCopyWithImpl<$Res>
    extends _$AstroProjectCopyWithImpl<$Res, _$AstroProjectImpl>
    implements _$$AstroProjectImplCopyWith<$Res> {
  __$$AstroProjectImplCopyWithImpl(
    _$AstroProjectImpl _value,
    $Res Function(_$AstroProjectImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AstroProject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? sourceVideoUri = null,
    Object? thumbnailPath = freezed,
    Object? projectType = null,
    Object? status = null,
    Object? resultImagePath = freezed,
    Object? stabilizedVideoPath = freezed,
    Object? stabilizationConfig = freezed,
    Object? stackConfig = freezed,
    Object? metadata = freezed,
  }) {
    return _then(
      _$AstroProjectImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        sourceVideoUri: null == sourceVideoUri
            ? _value.sourceVideoUri
            : sourceVideoUri // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbnailPath: freezed == thumbnailPath
            ? _value.thumbnailPath
            : thumbnailPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectType: null == projectType
            ? _value.projectType
            : projectType // ignore: cast_nullable_to_non_nullable
                  as ProjectType,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ProcessingStage,
        resultImagePath: freezed == resultImagePath
            ? _value.resultImagePath
            : resultImagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        stabilizedVideoPath: freezed == stabilizedVideoPath
            ? _value.stabilizedVideoPath
            : stabilizedVideoPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        stabilizationConfig: freezed == stabilizationConfig
            ? _value.stabilizationConfig
            : stabilizationConfig // ignore: cast_nullable_to_non_nullable
                  as StabilizationConfig?,
        stackConfig: freezed == stackConfig
            ? _value.stackConfig
            : stackConfig // ignore: cast_nullable_to_non_nullable
                  as StackConfig?,
        metadata: freezed == metadata
            ? _value.metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as VideoMetadata?,
      ),
    );
  }
}

/// @nodoc

class _$AstroProjectImpl implements _AstroProject {
  const _$AstroProjectImpl({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceVideoUri,
    this.thumbnailPath,
    required this.projectType,
    this.status = ProcessingStage.idle,
    this.resultImagePath,
    this.stabilizedVideoPath,
    this.stabilizationConfig,
    this.stackConfig,
    this.metadata,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String sourceVideoUri;
  @override
  final String? thumbnailPath;
  @override
  final ProjectType projectType;
  @override
  @JsonKey()
  final ProcessingStage status;
  @override
  final String? resultImagePath;
  @override
  final String? stabilizedVideoPath;
  @override
  final StabilizationConfig? stabilizationConfig;
  @override
  final StackConfig? stackConfig;
  @override
  final VideoMetadata? metadata;

  @override
  String toString() {
    return 'AstroProject(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, sourceVideoUri: $sourceVideoUri, thumbnailPath: $thumbnailPath, projectType: $projectType, status: $status, resultImagePath: $resultImagePath, stabilizedVideoPath: $stabilizedVideoPath, stabilizationConfig: $stabilizationConfig, stackConfig: $stackConfig, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AstroProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.sourceVideoUri, sourceVideoUri) ||
                other.sourceVideoUri == sourceVideoUri) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.projectType, projectType) ||
                other.projectType == projectType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.resultImagePath, resultImagePath) ||
                other.resultImagePath == resultImagePath) &&
            (identical(other.stabilizedVideoPath, stabilizedVideoPath) ||
                other.stabilizedVideoPath == stabilizedVideoPath) &&
            (identical(other.stabilizationConfig, stabilizationConfig) ||
                other.stabilizationConfig == stabilizationConfig) &&
            (identical(other.stackConfig, stackConfig) ||
                other.stackConfig == stackConfig) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    createdAt,
    updatedAt,
    sourceVideoUri,
    thumbnailPath,
    projectType,
    status,
    resultImagePath,
    stabilizedVideoPath,
    stabilizationConfig,
    stackConfig,
    metadata,
  );

  /// Create a copy of AstroProject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AstroProjectImplCopyWith<_$AstroProjectImpl> get copyWith =>
      __$$AstroProjectImplCopyWithImpl<_$AstroProjectImpl>(this, _$identity);
}

abstract class _AstroProject implements AstroProject {
  const factory _AstroProject({
    required final String id,
    required final String name,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    required final String sourceVideoUri,
    final String? thumbnailPath,
    required final ProjectType projectType,
    final ProcessingStage status,
    final String? resultImagePath,
    final String? stabilizedVideoPath,
    final StabilizationConfig? stabilizationConfig,
    final StackConfig? stackConfig,
    final VideoMetadata? metadata,
  }) = _$AstroProjectImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String get sourceVideoUri;
  @override
  String? get thumbnailPath;
  @override
  ProjectType get projectType;
  @override
  ProcessingStage get status;
  @override
  String? get resultImagePath;
  @override
  String? get stabilizedVideoPath;
  @override
  StabilizationConfig? get stabilizationConfig;
  @override
  StackConfig? get stackConfig;
  @override
  VideoMetadata? get metadata;

  /// Create a copy of AstroProject
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AstroProjectImplCopyWith<_$AstroProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
