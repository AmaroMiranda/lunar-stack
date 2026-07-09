import 'package:go_router/go_router.dart';

import '../features/analysis/presentation/analysis_screen.dart';
import '../features/flow_selection/presentation/flow_selection_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/import_video/presentation/import_screen.dart';
import '../features/processing/presentation/processing_screen.dart';
import '../features/result/presentation/result_screen.dart';
import '../features/result/presentation/video_result_screen.dart';
import '../features/stacking/presentation/stack_config_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/import', builder: (context, state) => const ImportScreen()),
    GoRoute(path: '/flow', builder: (context, state) => const FlowSelectionScreen()),
    GoRoute(path: '/analysis', builder: (context, state) => const AnalysisScreen()),
    GoRoute(path: '/stack-config', builder: (context, state) => const StackConfigScreen()),
    GoRoute(path: '/processing', builder: (context, state) => const ProcessingScreen()),
    GoRoute(path: '/result', builder: (context, state) => const ResultScreen()),
    GoRoute(path: '/result-video', builder: (context, state) => const VideoResultScreen()),
    GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
  ],
);
