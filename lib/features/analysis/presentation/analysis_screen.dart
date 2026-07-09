import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/domain/frame_quality.dart';
import '../../../core/native/astro_engine_bindings.dart';
import '../../../core/native/frame_extractor_channel.dart';
import '../../../core/widgets/astro_card.dart';
import '../../../core/widgets/astro_metric_chip.dart';
import '../../../core/widgets/astro_quality_graph.dart';
import '../domain/frame_selection_suggestion.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

enum _Phase { extracting, analyzing, done, failed }

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  _Phase _phase = _Phase.extracting;
  int _current = 0;
  int _total = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final metadata = ref.read(projectDraftProvider).metadata;
    if (metadata == null) return;

    final extractor = FrameExtractorChannel();
    final progressSub = extractor.progressStream().listen((p) {
      if (mounted) {
        setState(() {
          _phase = p.phase == 'analyze' ? _Phase.analyzing : _Phase.extracting;
          _current = p.current;
          _total = p.total;
        });
      }
    });

    try {
      // Preferred path: sequential MediaCodec decode of EVERY frame in one
      // pass — real frame count, real per-frame quality, no 60-frame cap.
      // Full frames are only extracted later (in processing) for the frames
      // that actually get selected.
      try {
        final analysis = await extractor.analyzeVideo(videoPath: metadata.uri);
        if (analysis.scores.length < 2) {
          throw PlatformException(code: 'TOO_FEW_FRAMES');
        }
        final maxRaw = analysis.scores.reduce((a, b) => a > b ? a : b);
        final denom = maxRaw > 1e-9 ? maxRaw : 1.0;
        final frames = [
          for (var i = 0; i < analysis.scores.length; i++)
            FrameQuality(
              frameIndex: i,
              timestampMs: (i * 1000 / analysis.fps).round(),
              qualityScore: (analysis.scores[i] / denom).clamp(0.0, 1.0),
              sharpnessScore: (analysis.scores[i] / denom).clamp(0.0, 1.0),
              contrastScore: (analysis.scores[i] / denom).clamp(0.0, 1.0),
              exposurePenalty: 0.0,
              stabilizationConfidence: (analysis.scores[i] / denom).clamp(0.0, 1.0),
            ),
        ];
        final suggestion = suggestFrameSelectionPercent(frames);
        ref.read(projectDraftProvider.notifier).setFrameAnalysis(
              framePaths: const [],  // extraídos depois, só os selecionados
              frames: frames,
              suggestedPercent: suggestion.percent,
              reason: suggestion.reason,
            );
        if (mounted) setState(() => _phase = _Phase.done);
        return;
      } on PlatformException {
        // MediaCodec path failed on this device/file — fall back to the
        // legacy retriever-based sampling below.
      }

      final tempDir = await getTemporaryDirectory();
      final framesDir = '${tempDir.path}/lunar_stack_frames_${DateTime.now().millisecondsSinceEpoch}';
      final extraction = await extractor.extractFrames(
        videoPath: metadata.uri,
        outputDir: framesDir,
        targetFrameCount: 60,
      );

      if (extraction.framePaths.length < 2) {
        setState(() {
          _phase = _Phase.failed;
          _errorMessage = 'Não consegui extrair frames suficientes desse vídeo.';
        });
        return;
      }

      setState(() {
        _phase = _Phase.analyzing;
        _current = 0;
        _total = extraction.framePaths.length;
      });

      final scores = await withEngineProgress(
        () => analyzeFramesIsolate(extraction.framePaths),
        (progress) {
          if (mounted) {
            setState(() {
              _current = progress.current;
              _total = progress.total;
            });
          }
        },
      );

      final frames = [
        for (var i = 0; i < scores.length; i++)
          FrameQuality(
            frameIndex: i,
            timestampMs: extraction.framePaths.isEmpty
                ? 0
                : (i * extraction.durationMs / extraction.framePaths.length).round(),
            qualityScore: scores[i],
            sharpnessScore: scores[i],
            contrastScore: scores[i],
            exposurePenalty: 0.0,
            stabilizationConfidence: scores[i],
          ),
      ];
      final suggestion = suggestFrameSelectionPercent(frames);

      ref.read(projectDraftProvider.notifier).setFrameAnalysis(
            framePaths: extraction.framePaths,
            frames: frames,
            suggestedPercent: suggestion.percent,
            reason: suggestion.reason,
          );

      if (mounted) setState(() => _phase = _Phase.done);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _errorMessage = _friendlyError(e);
        });
      }
    } finally {
      await progressSub.cancel();
    }
  }

  // Turn raw platform/engine exceptions into calm, non-technical guidance
  // (spec section 22.2), instead of surfacing e.g. "PlatformException(...)".
  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('setdatasource') || s.contains('extraction') || s.contains('0x80000000')) {
      return 'Não consegui ler esse arquivo como vídeo. Selecione um vídeo MP4 da Lua e tente de novo.';
    }
    if (s.contains('outofmemory') || s.contains('memory')) {
      return 'Esse vídeo é pesado demais para o aparelho. Tente um vídeo mais curto ou de menor resolução.';
    }
    return 'Não consegui analisar esse vídeo. Tente exportar em MP4 e importar novamente.';
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(projectDraftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Análise de frames')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: switch (_phase) {
            _Phase.extracting => _LoadingBody(
                message: 'Extraindo frames do vídeo...',
                current: _current,
                total: _total,
              ),
            _Phase.analyzing => _LoadingBody(
                message: 'Calculando nitidez dos frames...',
                current: _current,
                total: _total,
              ),
            _Phase.failed => Center(
                child: Text(
                  _errorMessage ?? 'Não consegui analisar esse vídeo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            _Phase.done => _AnalysisResult(
                frames: draft.frameQualities,
                suggestedPercent: draft.suggestedPercent ?? 25,
                reason: draft.suggestionReason ?? '',
                onContinue: () => context.push('/stack-config'),
              ),
          },
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.message, required this.current, required this.total});
  final String message;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (total > 0) ...[
            const SizedBox(height: 4),
            Text('$current/$total', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _AnalysisResult extends StatelessWidget {
  const _AnalysisResult({
    required this.frames,
    required this.suggestedPercent,
    required this.reason,
    required this.onContinue,
  });

  final List<FrameQuality> frames;
  final int suggestedPercent;
  final String reason;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bestFrame = frames.isEmpty
        ? null
        : frames.reduce((a, b) => a.qualityScore > b.qualityScore ? a : b);
    final threshold = frames.isEmpty
        ? 0.5
        : (frames.map((f) => f.qualityScore).toList()..sort())[
            (frames.length * (1 - suggestedPercent / 100)).clamp(0, frames.length - 1).round()];

    return ListView(
      children: [
        Text('Análise concluída.', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'O vídeo tem ${frames.length} frames analisados.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        AstroCard(child: AstroQualityGraph(frames: frames, thresholdScore: threshold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AstroMetricChip(label: '${frames.length} frames'),
            if (bestFrame != null)
              AstroMetricChip(label: 'Melhor frame: #${bestFrame.frameIndex}'),
          ],
        ),
        const SizedBox(height: 16),
        AstroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Text('Sugestão automática', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text('Use os melhores $suggestedPercent% dos frames.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(reason, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Usar sugestão'),
        ),
      ],
    );
  }
}
