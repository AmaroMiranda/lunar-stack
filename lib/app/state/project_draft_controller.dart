import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/domain/frame_quality.dart';
import '../../core/domain/processing_stage.dart';
import '../../core/domain/project_type.dart';
import '../../core/domain/stack_config.dart';
import '../../core/domain/stack_result.dart';
import '../../core/domain/video_metadata.dart';
import '../../core/native/astro_engine_bindings.dart';
import '../../core/native/frame_extractor_channel.dart';
import 'project_draft.dart';

final projectDraftProvider = NotifierProvider<ProjectDraftController, ProjectDraft>(
  ProjectDraftController.new,
);

class ProjectDraftController extends Notifier<ProjectDraft> {
  final _extractor = FrameExtractorChannel();

  @override
  ProjectDraft build() => const ProjectDraft();

  void reset() {
    AstroEngine.instance.cancel();
    _extractor.cancelExtraction();
    state = const ProjectDraft();
  }

  void setVideo(VideoMetadata metadata) {
    state = state.copyWith(metadata: metadata);
  }

  void setProjectType(ProjectType type) {
    state = state.copyWith(projectType: type);
  }

  void updateStackConfig(StackConfig Function(StackConfig) update) {
    state = state.copyWith(stackConfig: update(state.stackConfig));
  }

  /// Real per-frame quality from the Analysis screen. In the sequential
  /// (preferred) path `framePaths` is empty — the selected frames are only
  /// extracted from the video during [runProcessing]. The legacy fallback
  /// still passes pre-extracted paths.
  void setFrameAnalysis({
    required List<String> framePaths,
    required List<FrameQuality> frames,
    required int suggestedPercent,
    required String reason,
  }) {
    state = state.copyWith(
      framePaths: framePaths,
      frameQualities: frames,
      framesTotal: frames.length,
      suggestedPercent: suggestedPercent,
      suggestionReason: reason,
      stackConfig: state.stackConfig.copyWith(frameSelectionPercent: suggestedPercent),
    );
  }

  void cancelProcessing() {
    AstroEngine.instance.cancel();
    _extractor.cancelExtraction();
  }

  /// Real pipeline: pick the top N% frames by measured quality (capped by
  /// maxFrames), extract exactly those from the video (sequential decode),
  /// then align+stack with the native engine. The stabilization flow skips
  /// analysis entirely and re-encodes the clip on the Kotlin side.
  Future<void> runProcessing() async {
    if (state.projectType == ProjectType.stabilization) {
      return _runStabilization();
    }
    final metadata = state.metadata;
    if (metadata == null || state.frameQualities.isEmpty) return;

    state = state.copyWith(stage: ProcessingStage.validating, overallProgress: 0.0);

    final sortedByQuality = [...state.frameQualities]
      ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    final total = state.frameQualities.length;
    final keepCount = (total * state.stackConfig.frameSelectionPercent / 100)
        .round()
        .clamp(2, total)
        .clamp(2, state.stackConfig.maxFrames);
    final selectedIndices = sortedByQuality.take(keepCount).map((f) => f.frameIndex).toList()
      ..sort();

    state = state.copyWith(
      stage: ProcessingStage.selectingFrames,
      overallProgress: 0.02,
      framesTotal: keepCount,
      framesProcessed: 0,
    );

    StreamSubscription<({String phase, int current, int total})>? extractSub;
    try {
      // -- Extract only the selected frames (unless the legacy fallback
      //    already produced pre-extracted files during analysis) ------------
      List<String> selectedPaths;
      if (state.framePaths.isNotEmpty) {
        selectedPaths = [for (final i in selectedIndices) state.framePaths[i]];
      } else {
        extractSub = _extractor.progressStream().listen((p) {
          if (p.phase != 'extract') return;
          state = state.copyWith(
            stage: ProcessingStage.decoding,
            framesProcessed: p.current,
            framesTotal: p.total,
            overallProgress: 0.02 + 0.28 * (p.total == 0 ? 0 : p.current / p.total),
          );
        });
        final tempDir = await getTemporaryDirectory();
        final framesDir =
            '${tempDir.path}/lunar_stack_sel_${DateTime.now().millisecondsSinceEpoch}';
        selectedPaths = await _extractor.extractSelected(
          videoPath: metadata.uri,
          outputDir: framesDir,
          indices: selectedIndices,
          // "Estabilizar + empilhar": pré-centraliza a Lua em cada frame
          // salvo (shift inteiro, sem re-encode) — absorve tremores grandes
          // que o registro global rejeitaria como implausíveis.
          centerMoon: state.projectType == ProjectType.stabilizationPlusStacking,
        );
        await extractSub.cancel();
        extractSub = null;
        if (selectedPaths.length < 2) {
          state = state.copyWith(
            stage: ProcessingStage.failed,
            errorMessage: 'Não consegui extrair os frames selecionados do vídeo.',
          );
          return;
        }
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${docsDir.path}/lunar_stack_results');
      if (!resultsDir.existsSync()) resultsDir.createSync(recursive: true);
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final ext = state.stackConfig.outputFormat.extension;
      final outPath = '${resultsDir.path}/stack_$stamp.$ext';
      final previewPath = '${resultsDir.path}/stack_${stamp}_preview.jpg';

      final options = EngineStackOptions(
        stackingMethod: state.stackConfig.stackingMethod == StackingMethod.weightedAverage
            ? EngineStackingMethod.weightedAverage
            : EngineStackingMethod.simpleAverage,
        autoCrop: state.stackConfig.autoCropEnabled,
        // Modo cru: nenhum ajuste na imagem — só alinhamento + média.
        sharpen: !state.stackConfig.rawMode && state.stackConfig.sharpenMode,
      );

      final stopwatch = Stopwatch()..start();
      final result = await withEngineProgress(
        () => stackIsolate(
          paths: selectedPaths,
          options: options,
          outPath: outPath,
          previewPath: previewPath,
        ),
        (progress) {
          final stage = switch (progress.stage) {
            EngineStage.stacking => ProcessingStage.stacking,
            EngineStage.encoding => ProcessingStage.exporting,
            EngineStage.done => ProcessingStage.exporting,
            _ => ProcessingStage.aligning,
          };
          state = state.copyWith(
            stage: stage,
            overallProgress: 0.30 + 0.70 * progress.fraction,
            framesProcessed: progress.current,
            framesTotal: progress.total == 0 ? state.framesTotal : progress.total,
          );
        },
      );
      stopwatch.stop();

      state = state.copyWith(
        stage: ProcessingStage.done,
        overallProgress: 1.0,
        stackResult: StackResult(
          outputPath: outPath,
          previewPath: previewPath,
          width: result.width,
          height: result.height,
          framesAnalyzed: total,
          framesStacked: result.framesStacked,
          processingTimeMs: stopwatch.elapsedMilliseconds,
          stackingMethod: state.stackConfig.stackingMethod,
          alignmentMethod: AlignmentMethod.globalPhaseCorrelation,
        ),
        referenceFramePath: selectedPaths[result.referenceIndex],
      );
    } on EngineException catch (e) {
      if (e.code == kEngineCancelledCode) {
        state = state.copyWith(stage: ProcessingStage.cancelled);
      } else {
        state = state.copyWith(stage: ProcessingStage.failed, errorMessage: e.message);
      }
    } on Exception catch (e) {
      final cancelled = e.toString().toLowerCase().contains('cancel');
      state = state.copyWith(
        stage: cancelled ? ProcessingStage.cancelled : ProcessingStage.failed,
        errorMessage: cancelled
            ? null
            : 'Não consegui processar esse vídeo. Tente novamente ou use outro arquivo.',
      );
    } finally {
      await extractSub?.cancel();
    }
  }

  /// "Apenas estabilizar": Kotlin decodes, centers the Moon per frame and
  /// re-encodes to MP4 — the whole pipeline runs device-side in one pass.
  Future<void> _runStabilization() async {
    final metadata = state.metadata;
    if (metadata == null) return;

    state = state.copyWith(
      stage: ProcessingStage.detectingObject,
      overallProgress: 0.02,
      framesProcessed: 0,
      framesTotal: 0,
    );

    StreamSubscription<({String phase, int current, int total})>? sub;
    try {
      sub = _extractor.progressStream().listen((p) {
        if (p.phase != 'stabilize') return;
        state = state.copyWith(
          stage: ProcessingStage.stabilizing,
          framesProcessed: p.current,
          framesTotal: p.total,
          overallProgress: 0.02 + 0.96 * (p.total == 0 ? 0 : p.current / p.total),
        );
      });

      final docsDir = await getApplicationDocumentsDirectory();
      final resultsDir = Directory('${docsDir.path}/lunar_stack_results');
      if (!resultsDir.existsSync()) resultsDir.createSync(recursive: true);
      final outPath =
          '${resultsDir.path}/stab_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final result = await _extractor.stabilizeVideo(
        videoPath: metadata.uri,
        outPath: outPath,
      );

      state = state.copyWith(
        stage: ProcessingStage.done,
        overallProgress: 1.0,
        stabilizedVideoPath: result.path,
        stabilizedWidth: result.width,
        stabilizedHeight: result.height,
        stabilizedFrames: result.frames,
      );
    } on Exception catch (e) {
      final cancelled = e.toString().toLowerCase().contains('cancel');
      state = state.copyWith(
        stage: cancelled ? ProcessingStage.cancelled : ProcessingStage.failed,
        errorMessage: cancelled
            ? null
            : 'Não consegui estabilizar esse vídeo. Tente novamente ou use outro arquivo.',
      );
    } finally {
      await sub?.cancel();
    }
  }
}
