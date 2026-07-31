import 'package:go_router/go_router.dart';

import '../features/analysis/presentation/analysis_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/import_images/presentation/image_import_screen.dart';
import '../features/import_video/presentation/import_screen.dart';
import '../features/mineral/presentation/mineral_screen.dart';
import '../features/processing/presentation/processing_screen.dart';
import '../features/result/presentation/result_screen.dart';
import '../features/result/presentation/video_result_screen.dart';
import '../features/stacking/presentation/stack_config_screen.dart';
import '../features/wavelets/presentation/wavelet_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/import', builder: (context, state) => const ImportScreen()),
    GoRoute(path: '/import-images', builder: (context, state) => const ImageImportScreen()),
    GoRoute(path: '/analysis', builder: (context, state) => const AnalysisScreen()),
    GoRoute(path: '/stack-config', builder: (context, state) => const StackConfigScreen()),
    GoRoute(path: '/processing', builder: (context, state) => const ProcessingScreen()),
    GoRoute(path: '/result', builder: (context, state) => const ResultScreen()),
    GoRoute(path: '/wavelets', builder: (context, state) => const WaveletScreen()),
    GoRoute(
      path: '/mineral',
      // `extra` = caminho da imagem escolhida (modo estúdio, pela home). Sem
      // extra = modo resultado (grada o mestre do stack).
      builder: (context, state) => MineralScreen(sourcePath: state.extra as String?),
    ),
    GoRoute(path: '/result-video', builder: (context, state) => const VideoResultScreen()),
    GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
  ],
);
