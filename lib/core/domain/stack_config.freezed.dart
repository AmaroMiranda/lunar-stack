// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stack_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$StackConfig {
  int get frameSelectionPercent => throw _privateConstructorUsedError;
  int get maxFrames => throw _privateConstructorUsedError;
  StackingMethod get stackingMethod => throw _privateConstructorUsedError;
  AlignmentMethod get alignmentMethod => throw _privateConstructorUsedError;
  bool get useStabilizationData => throw _privateConstructorUsedError;
  bool get sharpenMode =>
      throw _privateConstructorUsedError; // Empilhamento cru: só alinhar e tirar a média — nenhum ajuste de
  // nitidez/tom na imagem final. Tem precedência sobre [sharpenMode].
  bool get rawMode => throw _privateConstructorUsedError;
  bool get autoCropEnabled => throw _privateConstructorUsedError;
  OutputFormat get outputFormat => throw _privateConstructorUsedError;

  /// Create a copy of StackConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StackConfigCopyWith<StackConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StackConfigCopyWith<$Res> {
  factory $StackConfigCopyWith(
    StackConfig value,
    $Res Function(StackConfig) then,
  ) = _$StackConfigCopyWithImpl<$Res, StackConfig>;
  @useResult
  $Res call({
    int frameSelectionPercent,
    int maxFrames,
    StackingMethod stackingMethod,
    AlignmentMethod alignmentMethod,
    bool useStabilizationData,
    bool sharpenMode,
    bool rawMode,
    bool autoCropEnabled,
    OutputFormat outputFormat,
  });
}

/// @nodoc
class _$StackConfigCopyWithImpl<$Res, $Val extends StackConfig>
    implements $StackConfigCopyWith<$Res> {
  _$StackConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StackConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameSelectionPercent = null,
    Object? maxFrames = null,
    Object? stackingMethod = null,
    Object? alignmentMethod = null,
    Object? useStabilizationData = null,
    Object? sharpenMode = null,
    Object? rawMode = null,
    Object? autoCropEnabled = null,
    Object? outputFormat = null,
  }) {
    return _then(
      _value.copyWith(
            frameSelectionPercent: null == frameSelectionPercent
                ? _value.frameSelectionPercent
                : frameSelectionPercent // ignore: cast_nullable_to_non_nullable
                      as int,
            maxFrames: null == maxFrames
                ? _value.maxFrames
                : maxFrames // ignore: cast_nullable_to_non_nullable
                      as int,
            stackingMethod: null == stackingMethod
                ? _value.stackingMethod
                : stackingMethod // ignore: cast_nullable_to_non_nullable
                      as StackingMethod,
            alignmentMethod: null == alignmentMethod
                ? _value.alignmentMethod
                : alignmentMethod // ignore: cast_nullable_to_non_nullable
                      as AlignmentMethod,
            useStabilizationData: null == useStabilizationData
                ? _value.useStabilizationData
                : useStabilizationData // ignore: cast_nullable_to_non_nullable
                      as bool,
            sharpenMode: null == sharpenMode
                ? _value.sharpenMode
                : sharpenMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            rawMode: null == rawMode
                ? _value.rawMode
                : rawMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            autoCropEnabled: null == autoCropEnabled
                ? _value.autoCropEnabled
                : autoCropEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            outputFormat: null == outputFormat
                ? _value.outputFormat
                : outputFormat // ignore: cast_nullable_to_non_nullable
                      as OutputFormat,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StackConfigImplCopyWith<$Res>
    implements $StackConfigCopyWith<$Res> {
  factory _$$StackConfigImplCopyWith(
    _$StackConfigImpl value,
    $Res Function(_$StackConfigImpl) then,
  ) = __$$StackConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int frameSelectionPercent,
    int maxFrames,
    StackingMethod stackingMethod,
    AlignmentMethod alignmentMethod,
    bool useStabilizationData,
    bool sharpenMode,
    bool rawMode,
    bool autoCropEnabled,
    OutputFormat outputFormat,
  });
}

/// @nodoc
class __$$StackConfigImplCopyWithImpl<$Res>
    extends _$StackConfigCopyWithImpl<$Res, _$StackConfigImpl>
    implements _$$StackConfigImplCopyWith<$Res> {
  __$$StackConfigImplCopyWithImpl(
    _$StackConfigImpl _value,
    $Res Function(_$StackConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StackConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameSelectionPercent = null,
    Object? maxFrames = null,
    Object? stackingMethod = null,
    Object? alignmentMethod = null,
    Object? useStabilizationData = null,
    Object? sharpenMode = null,
    Object? rawMode = null,
    Object? autoCropEnabled = null,
    Object? outputFormat = null,
  }) {
    return _then(
      _$StackConfigImpl(
        frameSelectionPercent: null == frameSelectionPercent
            ? _value.frameSelectionPercent
            : frameSelectionPercent // ignore: cast_nullable_to_non_nullable
                  as int,
        maxFrames: null == maxFrames
            ? _value.maxFrames
            : maxFrames // ignore: cast_nullable_to_non_nullable
                  as int,
        stackingMethod: null == stackingMethod
            ? _value.stackingMethod
            : stackingMethod // ignore: cast_nullable_to_non_nullable
                  as StackingMethod,
        alignmentMethod: null == alignmentMethod
            ? _value.alignmentMethod
            : alignmentMethod // ignore: cast_nullable_to_non_nullable
                  as AlignmentMethod,
        useStabilizationData: null == useStabilizationData
            ? _value.useStabilizationData
            : useStabilizationData // ignore: cast_nullable_to_non_nullable
                  as bool,
        sharpenMode: null == sharpenMode
            ? _value.sharpenMode
            : sharpenMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        rawMode: null == rawMode
            ? _value.rawMode
            : rawMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        autoCropEnabled: null == autoCropEnabled
            ? _value.autoCropEnabled
            : autoCropEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        outputFormat: null == outputFormat
            ? _value.outputFormat
            : outputFormat // ignore: cast_nullable_to_non_nullable
                  as OutputFormat,
      ),
    );
  }
}

/// @nodoc

class _$StackConfigImpl implements _StackConfig {
  const _$StackConfigImpl({
    this.frameSelectionPercent = 25,
    this.maxFrames = 500,
    this.stackingMethod = StackingMethod.weightedAverage,
    this.alignmentMethod = AlignmentMethod.globalPhaseCorrelation,
    this.useStabilizationData = true,
    this.sharpenMode = true,
    this.rawMode = false,
    this.autoCropEnabled = true,
    this.outputFormat = OutputFormat.png,
  });

  @override
  @JsonKey()
  final int frameSelectionPercent;
  @override
  @JsonKey()
  final int maxFrames;
  @override
  @JsonKey()
  final StackingMethod stackingMethod;
  @override
  @JsonKey()
  final AlignmentMethod alignmentMethod;
  @override
  @JsonKey()
  final bool useStabilizationData;
  @override
  @JsonKey()
  final bool sharpenMode;
  // Empilhamento cru: só alinhar e tirar a média — nenhum ajuste de
  // nitidez/tom na imagem final. Tem precedência sobre [sharpenMode].
  @override
  @JsonKey()
  final bool rawMode;
  @override
  @JsonKey()
  final bool autoCropEnabled;
  @override
  @JsonKey()
  final OutputFormat outputFormat;

  @override
  String toString() {
    return 'StackConfig(frameSelectionPercent: $frameSelectionPercent, maxFrames: $maxFrames, stackingMethod: $stackingMethod, alignmentMethod: $alignmentMethod, useStabilizationData: $useStabilizationData, sharpenMode: $sharpenMode, rawMode: $rawMode, autoCropEnabled: $autoCropEnabled, outputFormat: $outputFormat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StackConfigImpl &&
            (identical(other.frameSelectionPercent, frameSelectionPercent) ||
                other.frameSelectionPercent == frameSelectionPercent) &&
            (identical(other.maxFrames, maxFrames) ||
                other.maxFrames == maxFrames) &&
            (identical(other.stackingMethod, stackingMethod) ||
                other.stackingMethod == stackingMethod) &&
            (identical(other.alignmentMethod, alignmentMethod) ||
                other.alignmentMethod == alignmentMethod) &&
            (identical(other.useStabilizationData, useStabilizationData) ||
                other.useStabilizationData == useStabilizationData) &&
            (identical(other.sharpenMode, sharpenMode) ||
                other.sharpenMode == sharpenMode) &&
            (identical(other.rawMode, rawMode) || other.rawMode == rawMode) &&
            (identical(other.autoCropEnabled, autoCropEnabled) ||
                other.autoCropEnabled == autoCropEnabled) &&
            (identical(other.outputFormat, outputFormat) ||
                other.outputFormat == outputFormat));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    frameSelectionPercent,
    maxFrames,
    stackingMethod,
    alignmentMethod,
    useStabilizationData,
    sharpenMode,
    rawMode,
    autoCropEnabled,
    outputFormat,
  );

  /// Create a copy of StackConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StackConfigImplCopyWith<_$StackConfigImpl> get copyWith =>
      __$$StackConfigImplCopyWithImpl<_$StackConfigImpl>(this, _$identity);
}

abstract class _StackConfig implements StackConfig {
  const factory _StackConfig({
    final int frameSelectionPercent,
    final int maxFrames,
    final StackingMethod stackingMethod,
    final AlignmentMethod alignmentMethod,
    final bool useStabilizationData,
    final bool sharpenMode,
    final bool rawMode,
    final bool autoCropEnabled,
    final OutputFormat outputFormat,
  }) = _$StackConfigImpl;

  @override
  int get frameSelectionPercent;
  @override
  int get maxFrames;
  @override
  StackingMethod get stackingMethod;
  @override
  AlignmentMethod get alignmentMethod;
  @override
  bool get useStabilizationData;
  @override
  bool get sharpenMode; // Empilhamento cru: só alinhar e tirar a média — nenhum ajuste de
  // nitidez/tom na imagem final. Tem precedência sobre [sharpenMode].
  @override
  bool get rawMode;
  @override
  bool get autoCropEnabled;
  @override
  OutputFormat get outputFormat;

  /// Create a copy of StackConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StackConfigImplCopyWith<_$StackConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
