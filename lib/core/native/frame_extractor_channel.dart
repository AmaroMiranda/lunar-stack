import 'package:flutter/services.dart';

class FrameExtractionResult {
  const FrameExtractionResult({
    required this.durationMs,
    required this.width,
    required this.height,
    required this.nativeFrameCount,
    required this.fps,
    required this.framePaths,
  });

  final int durationMs;
  final int width;
  final int height;
  final int nativeFrameCount;
  final double fps;
  final List<String> framePaths;
}

class StabilizationResult {
  const StabilizationResult({
    required this.path,
    required this.width,
    required this.height,
    required this.frames,
    required this.durationMs,
  });

  final String path;
  final int width;
  final int height;
  final int frames;
  final int durationMs;
}

class VideoAnalysisResult {
  const VideoAnalysisResult({
    required this.durationMs,
    required this.width,
    required this.height,
    required this.frameCount,
    required this.fps,
    required this.scores,
  });

  final int durationMs;
  final int width;
  final int height;
  final int frameCount;
  final double fps;

  /// Raw (unnormalized) sharpness per frame, index == frame index.
  final List<double> scores;
}

/// Bridge to the Kotlin side. Frame decoding lives there because the vendored
/// OpenCV Android build has no video I/O backend.
///
/// Two-pass architecture (spec 12.2/16.2), via `SequentialFrameExtractor.kt`:
/// [analyzeVideo] decodes every frame once and returns a sharpness score per
/// frame; [extractSelected] decodes again saving only the chosen indices as
/// PNG. [extractFrames] is the old retriever-based sampler, kept as fallback.
class FrameExtractorChannel {
  static const _methodChannel = MethodChannel('com.astrostack.lunar_stack/frame_extractor');
  static const _progressChannel =
      EventChannel('com.astrostack.lunar_stack/frame_extractor_progress');

  Stream<({String phase, int current, int total})> progressStream() {
    return _progressChannel.receiveBroadcastStream().map((event) {
      final map = event as Map<Object?, Object?>;
      return (
        phase: (map['phase'] as String?) ?? 'extract',
        current: map['current'] as int,
        total: map['total'] as int,
      );
    });
  }

  Future<VideoAnalysisResult> analyzeVideo({required String videoPath}) async {
    final result = await _methodChannel.invokeMapMethod<String, Object?>('analyzeVideo', {
      'videoPath': videoPath,
    });
    if (result == null) {
      throw PlatformException(code: 'NULL_RESULT', message: 'analyzeVideo returned null');
    }
    return VideoAnalysisResult(
      durationMs: result['durationMs'] as int,
      width: result['width'] as int,
      height: result['height'] as int,
      frameCount: result['frameCount'] as int,
      fps: (result['fps'] as num).toDouble(),
      scores: (result['scores'] as List).cast<num>().map((e) => e.toDouble()).toList(),
    );
  }

  /// [centerMoon] enables the "Estabilizar + empilhar" pre-alignment: frames
  /// are saved with the Moon integer-shifted to the frame center (no
  /// resampling), so the stacker's registration only handles the residual.
  Future<List<String>> extractSelected({
    required String videoPath,
    required String outputDir,
    required List<int> indices,
    bool centerMoon = false,
  }) async {
    final result = await _methodChannel.invokeListMethod<String>('extractSelected', {
      'videoPath': videoPath,
      'outputDir': outputDir,
      'indices': indices,
      'centerMoon': centerMoon,
    });
    return result ?? const [];
  }

  Future<void> cancelExtraction() => _methodChannel.invokeMethod('cancelExtraction');

  /// "Apenas estabilizar": re-encodes the clip with the Moon center-locked.
  /// Progress arrives on [progressStream] with phase 'stabilize'.
  Future<StabilizationResult> stabilizeVideo({
    required String videoPath,
    required String outPath,
  }) async {
    final result = await _methodChannel.invokeMapMethod<String, Object?>('stabilizeVideo', {
      'videoPath': videoPath,
      'outPath': outPath,
    });
    if (result == null) {
      throw PlatformException(code: 'NULL_RESULT', message: 'stabilizeVideo returned null');
    }
    return StabilizationResult(
      path: result['path'] as String,
      width: result['width'] as int,
      height: result['height'] as int,
      frames: result['frames'] as int,
      durationMs: result['durationMs'] as int,
    );
  }

  /// Copies a produced file into public Downloads/LunarStack via MediaStore.
  /// Returns the user-visible relative path.
  Future<String> saveToDownloads({required String path, required String mime}) async {
    final result = await _methodChannel.invokeMethod<String>('saveToDownloads', {
      'path': path,
      'mime': mime,
    });
    return result ?? 'Downloads/LunarStack';
  }

  Future<FrameExtractionResult> extractFrames({
    required String videoPath,
    required String outputDir,
    int targetFrameCount = 180,
  }) async {
    final result = await _methodChannel.invokeMapMethod<String, Object?>('extractFrames', {
      'videoPath': videoPath,
      'outputDir': outputDir,
      'targetFrameCount': targetFrameCount,
    });
    if (result == null) {
      throw PlatformException(code: 'NULL_RESULT', message: 'extractFrames returned null');
    }
    return FrameExtractionResult(
      durationMs: result['durationMs'] as int,
      width: result['width'] as int,
      height: result['height'] as int,
      nativeFrameCount: result['nativeFrameCount'] as int,
      fps: (result['fps'] as num).toDouble(),
      framePaths: (result['framePaths'] as List).cast<String>(),
    );
  }
}
