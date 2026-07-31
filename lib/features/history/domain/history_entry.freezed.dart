// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HistoryEntry _$HistoryEntryFromJson(Map<String, dynamic> json) {
  return _HistoryEntry.fromJson(json);
}

/// @nodoc
mixin _$HistoryEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  ProjectType get projectType => throw _privateConstructorUsedError;
  ProcessingStage get status => throw _privateConstructorUsedError;
  String get summary => throw _privateConstructorUsedError;
  String? get sourceVideoUri =>
      throw _privateConstructorUsedError; // Caminho do resultado final salvo (imagem mestre ou vídeo estabilizado),
  // para reabrir o projeto e re-exportar. Prévia JPEG quando o mestre é TIFF.
  String? get resultPath => throw _privateConstructorUsedError;
  String? get previewPath => throw _privateConstructorUsedError;
  int? get resultWidth => throw _privateConstructorUsedError;
  int? get resultHeight => throw _privateConstructorUsedError;

  /// Serializes this HistoryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HistoryEntryCopyWith<HistoryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HistoryEntryCopyWith<$Res> {
  factory $HistoryEntryCopyWith(
    HistoryEntry value,
    $Res Function(HistoryEntry) then,
  ) = _$HistoryEntryCopyWithImpl<$Res, HistoryEntry>;
  @useResult
  $Res call({
    String id,
    String name,
    DateTime createdAt,
    ProjectType projectType,
    ProcessingStage status,
    String summary,
    String? sourceVideoUri,
    String? resultPath,
    String? previewPath,
    int? resultWidth,
    int? resultHeight,
  });
}

/// @nodoc
class _$HistoryEntryCopyWithImpl<$Res, $Val extends HistoryEntry>
    implements $HistoryEntryCopyWith<$Res> {
  _$HistoryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? projectType = null,
    Object? status = null,
    Object? summary = null,
    Object? sourceVideoUri = freezed,
    Object? resultPath = freezed,
    Object? previewPath = freezed,
    Object? resultWidth = freezed,
    Object? resultHeight = freezed,
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
            projectType: null == projectType
                ? _value.projectType
                : projectType // ignore: cast_nullable_to_non_nullable
                      as ProjectType,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ProcessingStage,
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceVideoUri: freezed == sourceVideoUri
                ? _value.sourceVideoUri
                : sourceVideoUri // ignore: cast_nullable_to_non_nullable
                      as String?,
            resultPath: freezed == resultPath
                ? _value.resultPath
                : resultPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            previewPath: freezed == previewPath
                ? _value.previewPath
                : previewPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            resultWidth: freezed == resultWidth
                ? _value.resultWidth
                : resultWidth // ignore: cast_nullable_to_non_nullable
                      as int?,
            resultHeight: freezed == resultHeight
                ? _value.resultHeight
                : resultHeight // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HistoryEntryImplCopyWith<$Res>
    implements $HistoryEntryCopyWith<$Res> {
  factory _$$HistoryEntryImplCopyWith(
    _$HistoryEntryImpl value,
    $Res Function(_$HistoryEntryImpl) then,
  ) = __$$HistoryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    DateTime createdAt,
    ProjectType projectType,
    ProcessingStage status,
    String summary,
    String? sourceVideoUri,
    String? resultPath,
    String? previewPath,
    int? resultWidth,
    int? resultHeight,
  });
}

/// @nodoc
class __$$HistoryEntryImplCopyWithImpl<$Res>
    extends _$HistoryEntryCopyWithImpl<$Res, _$HistoryEntryImpl>
    implements _$$HistoryEntryImplCopyWith<$Res> {
  __$$HistoryEntryImplCopyWithImpl(
    _$HistoryEntryImpl _value,
    $Res Function(_$HistoryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdAt = null,
    Object? projectType = null,
    Object? status = null,
    Object? summary = null,
    Object? sourceVideoUri = freezed,
    Object? resultPath = freezed,
    Object? previewPath = freezed,
    Object? resultWidth = freezed,
    Object? resultHeight = freezed,
  }) {
    return _then(
      _$HistoryEntryImpl(
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
        projectType: null == projectType
            ? _value.projectType
            : projectType // ignore: cast_nullable_to_non_nullable
                  as ProjectType,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ProcessingStage,
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceVideoUri: freezed == sourceVideoUri
            ? _value.sourceVideoUri
            : sourceVideoUri // ignore: cast_nullable_to_non_nullable
                  as String?,
        resultPath: freezed == resultPath
            ? _value.resultPath
            : resultPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        previewPath: freezed == previewPath
            ? _value.previewPath
            : previewPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        resultWidth: freezed == resultWidth
            ? _value.resultWidth
            : resultWidth // ignore: cast_nullable_to_non_nullable
                  as int?,
        resultHeight: freezed == resultHeight
            ? _value.resultHeight
            : resultHeight // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HistoryEntryImpl implements _HistoryEntry {
  const _$HistoryEntryImpl({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.projectType,
    required this.status,
    required this.summary,
    this.sourceVideoUri,
    this.resultPath,
    this.previewPath,
    this.resultWidth,
    this.resultHeight,
  });

  factory _$HistoryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$HistoryEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime createdAt;
  @override
  final ProjectType projectType;
  @override
  final ProcessingStage status;
  @override
  final String summary;
  @override
  final String? sourceVideoUri;
  // Caminho do resultado final salvo (imagem mestre ou vídeo estabilizado),
  // para reabrir o projeto e re-exportar. Prévia JPEG quando o mestre é TIFF.
  @override
  final String? resultPath;
  @override
  final String? previewPath;
  @override
  final int? resultWidth;
  @override
  final int? resultHeight;

  @override
  String toString() {
    return 'HistoryEntry(id: $id, name: $name, createdAt: $createdAt, projectType: $projectType, status: $status, summary: $summary, sourceVideoUri: $sourceVideoUri, resultPath: $resultPath, previewPath: $previewPath, resultWidth: $resultWidth, resultHeight: $resultHeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.projectType, projectType) ||
                other.projectType == projectType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.sourceVideoUri, sourceVideoUri) ||
                other.sourceVideoUri == sourceVideoUri) &&
            (identical(other.resultPath, resultPath) ||
                other.resultPath == resultPath) &&
            (identical(other.previewPath, previewPath) ||
                other.previewPath == previewPath) &&
            (identical(other.resultWidth, resultWidth) ||
                other.resultWidth == resultWidth) &&
            (identical(other.resultHeight, resultHeight) ||
                other.resultHeight == resultHeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    createdAt,
    projectType,
    status,
    summary,
    sourceVideoUri,
    resultPath,
    previewPath,
    resultWidth,
    resultHeight,
  );

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoryEntryImplCopyWith<_$HistoryEntryImpl> get copyWith =>
      __$$HistoryEntryImplCopyWithImpl<_$HistoryEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HistoryEntryImplToJson(this);
  }
}

abstract class _HistoryEntry implements HistoryEntry {
  const factory _HistoryEntry({
    required final String id,
    required final String name,
    required final DateTime createdAt,
    required final ProjectType projectType,
    required final ProcessingStage status,
    required final String summary,
    final String? sourceVideoUri,
    final String? resultPath,
    final String? previewPath,
    final int? resultWidth,
    final int? resultHeight,
  }) = _$HistoryEntryImpl;

  factory _HistoryEntry.fromJson(Map<String, dynamic> json) =
      _$HistoryEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  DateTime get createdAt;
  @override
  ProjectType get projectType;
  @override
  ProcessingStage get status;
  @override
  String get summary;
  @override
  String? get sourceVideoUri; // Caminho do resultado final salvo (imagem mestre ou vídeo estabilizado),
  // para reabrir o projeto e re-exportar. Prévia JPEG quando o mestre é TIFF.
  @override
  String? get resultPath;
  @override
  String? get previewPath;
  @override
  int? get resultWidth;
  @override
  int? get resultHeight;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoryEntryImplCopyWith<_$HistoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
