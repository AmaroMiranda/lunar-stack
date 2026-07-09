/// dart:ffi bindings for libastro_engine.so (see native/engine/include/astro_engine.h).
///
/// Hand-written: small API surface, easier to audit than generated output.
/// Keep in sync with the header.
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

/// Mirrors AsStatus::AS_ERR_CANCELLED in astro_engine.h.
const kEngineCancelledCode = 5;

class EngineException implements Exception {
  EngineException(this.code, this.message);
  final int code;
  final String message;

  @override
  String toString() => 'EngineException($code): $message';
}

enum EngineStage {
  idle,
  analyzing,
  aligning,
  stacking,
  encoding,
  done;

  static EngineStage fromNative(int value) {
    if (value < 0 || value >= EngineStage.values.length) return EngineStage.idle;
    return EngineStage.values[value];
  }
}

enum EngineStackingMethod { simpleAverage, weightedAverage }

class EngineProgress {
  const EngineProgress({
    required this.stage,
    required this.current,
    required this.total,
    required this.fraction,
  });

  final EngineStage stage;
  final int current;
  final int total;
  final double fraction;
}

class EngineStackResult {
  const EngineStackResult({
    required this.width,
    required this.height,
    required this.framesAnalyzed,
    required this.framesStacked,
    required this.referenceIndex,
  });

  final int width;
  final int height;
  final int framesAnalyzed;
  final int framesStacked;
  final int referenceIndex;
}

class EngineStackOptions {
  const EngineStackOptions({
    required this.stackingMethod,
    required this.autoCrop,
    required this.sharpen,
    this.previewMaxDim = 1600,
  });

  final EngineStackingMethod stackingMethod;
  final bool autoCrop;
  final bool sharpen;
  final int previewMaxDim;
}

// -- native structs -----------------------------------------------------------

final class _AsStackOptions extends Struct {
  @Int32()
  external int stackingMethod;
  @Int32()
  external int autoCrop;
  @Int32()
  external int sharpen;
  @Int32()
  external int previewMaxDim;
}

final class _AsProgress extends Struct {
  @Int32()
  external int stage;
  @Int32()
  external int current;
  @Int32()
  external int total;
  @Float()
  external double fraction;
}

final class _AsStackResult extends Struct {
  @Int32()
  external int width;
  @Int32()
  external int height;
  @Int32()
  external int framesAnalyzed;
  @Int32()
  external int framesStacked;
  @Int32()
  external int referenceIndex;
}

// -- native signatures ---------------------------------------------------------

typedef _VersionC = Int32 Function(Pointer<Utf8>, Int32);
typedef _VersionDart = int Function(Pointer<Utf8>, int);

typedef _AnalyzeC = Int32 Function(
    Pointer<Pointer<Utf8>>, Int32, Pointer<Double>, Pointer<Utf8>, Int32);
typedef _AnalyzeDart = int Function(
    Pointer<Pointer<Utf8>>, int, Pointer<Double>, Pointer<Utf8>, int);

typedef _StackC = Int32 Function(Pointer<Pointer<Utf8>>, Int32, Pointer<_AsStackOptions>,
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _StackDart = int Function(Pointer<Pointer<Utf8>>, int, Pointer<_AsStackOptions>,
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef _ConvertC = Int32 Function(
    Pointer<Utf8>, Pointer<Utf8>, Int32, Pointer<Utf8>, Int32);
typedef _ConvertDart = int Function(Pointer<Utf8>, Pointer<Utf8>, int, Pointer<Utf8>, int);

typedef _PollC = Void Function(Pointer<_AsProgress>);
typedef _PollDart = void Function(Pointer<_AsProgress>);

typedef _ResultC = Void Function(Pointer<_AsStackResult>);
typedef _ResultDart = void Function(Pointer<_AsStackResult>);

typedef _CancelC = Void Function();
typedef _CancelDart = void Function();

/// Thin, synchronous wrapper over the native library.
///
/// [analyzeFrames] and [stack] block the calling isolate — run them through
/// `Isolate.run`. [pollProgress] and [cancel] are cheap and thread-safe,
/// meant to be called from the main isolate while work runs elsewhere.
class AstroEngine {
  AstroEngine._(DynamicLibrary lib)
      : _version = lib.lookupFunction<_VersionC, _VersionDart>('as_version'),
        _analyze = lib.lookupFunction<_AnalyzeC, _AnalyzeDart>('as_analyze_frames'),
        _stack = lib.lookupFunction<_StackC, _StackDart>('as_stack'),
        _convert = lib.lookupFunction<_ConvertC, _ConvertDart>('as_convert_image'),
        _poll = lib.lookupFunction<_PollC, _PollDart>('as_poll_progress'),
        _result = lib.lookupFunction<_ResultC, _ResultDart>('as_get_stack_result'),
        _cancelFn = lib.lookupFunction<_CancelC, _CancelDart>('as_cancel');

  static AstroEngine? _instance;

  static AstroEngine get instance => _instance ??= AstroEngine._(_open());

  static DynamicLibrary _open() {
    if (Platform.isAndroid) return DynamicLibrary.open('libastro_engine.so');
    return DynamicLibrary.process();
  }

  final _VersionDart _version;
  final _AnalyzeDart _analyze;
  final _StackDart _stack;
  final _ConvertDart _convert;
  final _PollDart _poll;
  final _ResultDart _result;
  final _CancelDart _cancelFn;

  String version() {
    return using((arena) {
      final buf = arena.allocate<Utf8>(256);
      _version(buf, 256);
      return buf.toDartString();
    });
  }

  /// Blocking — call from a worker isolate. Returns normalized (0..1)
  /// sharpness scores, one per path, in the same order as [paths].
  List<double> analyzeFrames(List<String> paths) {
    return using((arena) {
      final pathPtrs = arena<Pointer<Utf8>>(paths.length);
      for (var i = 0; i < paths.length; i++) {
        pathPtrs[i] = paths[i].toNativeUtf8(allocator: arena);
      }
      final scores = arena<Double>(paths.length);
      const errLen = 512;
      final errBuf = arena.allocate<Utf8>(errLen);

      final rc = _analyze(pathPtrs, paths.length, scores, errBuf, errLen);
      if (rc != 0) {
        throw EngineException(rc, errBuf.toDartString());
      }
      return List.generate(paths.length, (i) => scores[i]);
    });
  }

  /// Blocking — call from a worker isolate.
  EngineStackResult stack({
    required List<String> paths,
    required EngineStackOptions options,
    required String outPath,
    required String previewPath,
  }) {
    return using((arena) {
      final pathPtrs = arena<Pointer<Utf8>>(paths.length);
      for (var i = 0; i < paths.length; i++) {
        pathPtrs[i] = paths[i].toNativeUtf8(allocator: arena);
      }
      final opt = arena<_AsStackOptions>();
      opt.ref
        ..stackingMethod = options.stackingMethod.index
        ..autoCrop = options.autoCrop ? 1 : 0
        ..sharpen = options.sharpen ? 1 : 0
        ..previewMaxDim = options.previewMaxDim;

      const errLen = 1024;
      final errBuf = arena.allocate<Utf8>(errLen);
      final rc = _stack(
        pathPtrs,
        paths.length,
        opt,
        outPath.toNativeUtf8(allocator: arena),
        previewPath.toNativeUtf8(allocator: arena),
        errBuf,
        errLen,
      );
      if (rc != 0) {
        throw EngineException(rc, errBuf.toDartString());
      }

      final res = arena<_AsStackResult>();
      _result(res);
      return EngineStackResult(
        width: res.ref.width,
        height: res.ref.height,
        framesAnalyzed: res.ref.framesAnalyzed,
        framesStacked: res.ref.framesStacked,
        referenceIndex: res.ref.referenceIndex,
      );
    });
  }

  /// Blocking — call from a worker isolate. Re-encodes [inPath] into
  /// [outPath]; the target format comes from outPath's extension.
  void convertImage({
    required String inPath,
    required String outPath,
    int jpegQuality = 95,
  }) {
    using((arena) {
      const errLen = 512;
      final errBuf = arena.allocate<Utf8>(errLen);
      final rc = _convert(
        inPath.toNativeUtf8(allocator: arena),
        outPath.toNativeUtf8(allocator: arena),
        jpegQuality,
        errBuf,
        errLen,
      );
      if (rc != 0) {
        throw EngineException(rc, errBuf.toDartString());
      }
    });
  }

  EngineProgress pollProgress() {
    return using((arena) {
      final p = arena<_AsProgress>();
      _poll(p);
      return EngineProgress(
        stage: EngineStage.fromNative(p.ref.stage),
        current: p.ref.current,
        total: p.ref.total,
        fraction: p.ref.fraction,
      );
    });
  }

  void cancel() => _cancelFn();
}

/// Top-level (not a method) so the closure `Isolate.run` serializes has no
/// enclosing `this` to drag along. A closure created inside a State method
/// that *also* touches `setState`/`mounted` elsewhere gets its whole
/// (non-sendable) instance context bundled in — `Isolate.spawn` then fails.
Future<List<double>> analyzeFramesIsolate(List<String> paths) {
  return Isolate.run(() => AstroEngine.instance.analyzeFrames(paths));
}

/// See [analyzeFramesIsolate] for why this must stay a top-level function.
Future<EngineStackResult> stackIsolate({
  required List<String> paths,
  required EngineStackOptions options,
  required String outPath,
  required String previewPath,
}) {
  return Isolate.run(() => AstroEngine.instance.stack(
        paths: paths,
        options: options,
        outPath: outPath,
        previewPath: previewPath,
      ));
}

/// See [analyzeFramesIsolate] for why this must stay a top-level function.
Future<void> convertImageIsolate({
  required String inPath,
  required String outPath,
  int jpegQuality = 95,
}) {
  return Isolate.run(() => AstroEngine.instance
      .convertImage(inPath: inPath, outPath: outPath, jpegQuality: jpegQuality));
}

/// Polls native progress on the calling isolate at a fixed cadence while
/// `task` runs (typically on a background isolate via `Isolate.run`) —
/// native globals are process-wide, so polling from here is safe.
Future<T> withEngineProgress<T>(
  Future<T> Function() task,
  void Function(EngineProgress) onProgress,
) async {
  final timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
    onProgress(AstroEngine.instance.pollProgress());
  });
  try {
    return await task();
  } finally {
    timer.cancel();
  }
}
