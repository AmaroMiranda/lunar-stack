// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stabilized_video_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$StabilizedVideoResult {
  String get outputPath => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;
  int get framesProcessed => throw _privateConstructorUsedError;
  bool get cropApplied => throw _privateConstructorUsedError;
  int get processingTimeMs => throw _privateConstructorUsedError;

  /// Create a copy of StabilizedVideoResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StabilizedVideoResultCopyWith<StabilizedVideoResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StabilizedVideoResultCopyWith<$Res> {
  factory $StabilizedVideoResultCopyWith(
    StabilizedVideoResult value,
    $Res Function(StabilizedVideoResult) then,
  ) = _$StabilizedVideoResultCopyWithImpl<$Res, StabilizedVideoResult>;
  @useResult
  $Res call({
    String outputPath,
    int width,
    int height,
    int durationMs,
    int framesProcessed,
    bool cropApplied,
    int processingTimeMs,
  });
}

/// @nodoc
class _$StabilizedVideoResultCopyWithImpl<
  $Res,
  $Val extends StabilizedVideoResult
>
    implements $StabilizedVideoResultCopyWith<$Res> {
  _$StabilizedVideoResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StabilizedVideoResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outputPath = null,
    Object? width = null,
    Object? height = null,
    Object? durationMs = null,
    Object? framesProcessed = null,
    Object? cropApplied = null,
    Object? processingTimeMs = null,
  }) {
    return _then(
      _value.copyWith(
            outputPath: null == outputPath
                ? _value.outputPath
                : outputPath // ignore: cast_nullable_to_non_nullable
                      as String,
            width: null == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as int,
            height: null == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as int,
            durationMs: null == durationMs
                ? _value.durationMs
                : durationMs // ignore: cast_nullable_to_non_nullable
                      as int,
            framesProcessed: null == framesProcessed
                ? _value.framesProcessed
                : framesProcessed // ignore: cast_nullable_to_non_nullable
                      as int,
            cropApplied: null == cropApplied
                ? _value.cropApplied
                : cropApplied // ignore: cast_nullable_to_non_nullable
                      as bool,
            processingTimeMs: null == processingTimeMs
                ? _value.processingTimeMs
                : processingTimeMs // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StabilizedVideoResultImplCopyWith<$Res>
    implements $StabilizedVideoResultCopyWith<$Res> {
  factory _$$StabilizedVideoResultImplCopyWith(
    _$StabilizedVideoResultImpl value,
    $Res Function(_$StabilizedVideoResultImpl) then,
  ) = __$$StabilizedVideoResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String outputPath,
    int width,
    int height,
    int durationMs,
    int framesProcessed,
    bool cropApplied,
    int processingTimeMs,
  });
}

/// @nodoc
class __$$StabilizedVideoResultImplCopyWithImpl<$Res>
    extends
        _$StabilizedVideoResultCopyWithImpl<$Res, _$StabilizedVideoResultImpl>
    implements _$$StabilizedVideoResultImplCopyWith<$Res> {
  __$$StabilizedVideoResultImplCopyWithImpl(
    _$StabilizedVideoResultImpl _value,
    $Res Function(_$StabilizedVideoResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StabilizedVideoResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outputPath = null,
    Object? width = null,
    Object? height = null,
    Object? durationMs = null,
    Object? framesProcessed = null,
    Object? cropApplied = null,
    Object? processingTimeMs = null,
  }) {
    return _then(
      _$StabilizedVideoResultImpl(
        outputPath: null == outputPath
            ? _value.outputPath
            : outputPath // ignore: cast_nullable_to_non_nullable
                  as String,
        width: null == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as int,
        height: null == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as int,
        durationMs: null == durationMs
            ? _value.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        framesProcessed: null == framesProcessed
            ? _value.framesProcessed
            : framesProcessed // ignore: cast_nullable_to_non_nullable
                  as int,
        cropApplied: null == cropApplied
            ? _value.cropApplied
            : cropApplied // ignore: cast_nullable_to_non_nullable
                  as bool,
        processingTimeMs: null == processingTimeMs
            ? _value.processingTimeMs
            : processingTimeMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$StabilizedVideoResultImpl implements _StabilizedVideoResult {
  const _$StabilizedVideoResultImpl({
    required this.outputPath,
    required this.width,
    required this.height,
    required this.durationMs,
    required this.framesProcessed,
    required this.cropApplied,
    required this.processingTimeMs,
  });

  @override
  final String outputPath;
  @override
  final int width;
  @override
  final int height;
  @override
  final int durationMs;
  @override
  final int framesProcessed;
  @override
  final bool cropApplied;
  @override
  final int processingTimeMs;

  @override
  String toString() {
    return 'StabilizedVideoResult(outputPath: $outputPath, width: $width, height: $height, durationMs: $durationMs, framesProcessed: $framesProcessed, cropApplied: $cropApplied, processingTimeMs: $processingTimeMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StabilizedVideoResultImpl &&
            (identical(other.outputPath, outputPath) ||
                other.outputPath == outputPath) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.framesProcessed, framesProcessed) ||
                other.framesProcessed == framesProcessed) &&
            (identical(other.cropApplied, cropApplied) ||
                other.cropApplied == cropApplied) &&
            (identical(other.processingTimeMs, processingTimeMs) ||
                other.processingTimeMs == processingTimeMs));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    outputPath,
    width,
    height,
    durationMs,
    framesProcessed,
    cropApplied,
    processingTimeMs,
  );

  /// Create a copy of StabilizedVideoResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StabilizedVideoResultImplCopyWith<_$StabilizedVideoResultImpl>
  get copyWith =>
      __$$StabilizedVideoResultImplCopyWithImpl<_$StabilizedVideoResultImpl>(
        this,
        _$identity,
      );
}

abstract class _StabilizedVideoResult implements StabilizedVideoResult {
  const factory _StabilizedVideoResult({
    required final String outputPath,
    required final int width,
    required final int height,
    required final int durationMs,
    required final int framesProcessed,
    required final bool cropApplied,
    required final int processingTimeMs,
  }) = _$StabilizedVideoResultImpl;

  @override
  String get outputPath;
  @override
  int get width;
  @override
  int get height;
  @override
  int get durationMs;
  @override
  int get framesProcessed;
  @override
  bool get cropApplied;
  @override
  int get processingTimeMs;

  /// Create a copy of StabilizedVideoResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StabilizedVideoResultImplCopyWith<_$StabilizedVideoResultImpl>
  get copyWith => throw _privateConstructorUsedError;
}
