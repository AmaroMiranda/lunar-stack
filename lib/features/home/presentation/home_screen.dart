import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../app/theme.dart';
import '../../../core/distribution.dart';
import '../../../core/domain/processing_stage.dart';
import '../../../core/domain/project_type.dart';
import '../../../core/services/update_prompt.dart';
import '../../../core/widgets/astro_card.dart';
import '../../../core/widgets/dotted_panel.dart';
import '../../../core/widgets/project_tile.dart';
import '../../../core/widgets/section_label.dart';
import '../../history/application/history_controller.dart';
import '../../history/domain/history_entry.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!isPlayStoreBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) maybePromptUpdate(context);
      });
    }
  }

  void _startVideo(ProjectType type) {
    ref.read(projectDraftProvider.notifier).reset();
    ref.read(projectDraftProvider.notifier).setProjectType(type);
    context.push('/import');
  }

  Future<void> _openMineral() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = res?.files.single.path;
    if (path == null || !mounted) return;
    context.push('/mineral', extra: path);
  }

  /// "Empilhar" une vídeo e fotos: a diferença é só a FONTE, então perguntamos
  /// aqui em vez de ter dois botões que fazem a mesma coisa. Vídeo já empilha
  /// centralizando a Lua (bom p/ tremido, inofensivo p/ estável — ajustável na
  /// configuração).
  Future<void> _chooseStackSource() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Empilhar a partir de…', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.movie_outlined),
              title: const Text('Um vídeo'),
              subtitle: const Text('O app escolhe os melhores frames'),
              onTap: () => Navigator.pop(ctx, 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Várias fotos'),
              subtitle: const Text('Você já tem as imagens'),
              onTap: () => Navigator.pop(ctx, 'photos'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (source == 'video') {
      _startVideo(ProjectType.stabilizationPlusStacking);
    } else {
      context.push('/import-images');
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            const _Brand(),
            const SizedBox(height: 22),

            // Ação principal: empilhar (fonte é escolhida depois — vídeo OU fotos).
            _PrimaryAction(
              icon: Icons.auto_awesome_outlined,
              title: 'Empilhar',
              description: 'Uma foto limpa e nítida da Lua — a partir de um vídeo ou de várias fotos.',
              onTap: _chooseStackSource,
            ),
            const SizedBox(height: 22),

            const SectionLabel('Outras ferramentas'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _ModeTile(
                  icon: Icons.videocam_outlined,
                  title: 'Estabilizar vídeo',
                  hint: 'Um vídeo mais parado',
                  accent: LunarColors.lunarPearl,
                  onTap: () => _startVideo(ProjectType.stabilization),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeTile(
                  icon: Icons.palette_outlined,
                  title: 'Lua Mineral',
                  hint: 'Realçar a cor',
                  accent: LunarColors.lunarGold,
                  onTap: _openMineral,
                ),
              ),
            ]),

            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SectionLabel('Projetos recentes'),
                TextButton(
                  onPressed: () => context.push('/history'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            history.when(
              data: (entries) => entries.isEmpty
                  ? const _EmptyRecents()
                  : Column(
                      children: entries
                          .take(3)
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ProjectTile(entry: e),
                              ))
                          .toList(),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview estático do layout da home (mock) — só para render/golden, não usa
/// Riverpod/router/plugins.
class HomePreview extends StatelessWidget {
  const HomePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final mock = [
      HistoryEntry(
        id: '1',
        name: 'Lua cheia — 4K 60fps',
        createdAt: DateTime(2026, 8, 6, 21, 14),
        projectType: ProjectType.stacking,
        status: ProcessingStage.done,
        summary: '192 frames · Média ponderada',
        resultPath: 'x.png',
      ),
      HistoryEntry(
        id: '2',
        name: 'Quarto crescente',
        createdAt: DateTime(2026, 8, 5, 22, 2),
        projectType: ProjectType.stabilizationPlusStacking,
        status: ProcessingStage.done,
        summary: '',
        resultPath: 'y.png',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            const _Brand(),
            const SizedBox(height: 22),
            _PrimaryAction(
              icon: Icons.auto_awesome_outlined,
              title: 'Empilhar',
              description: 'Uma foto limpa e nítida da Lua — a partir de um vídeo ou de várias fotos.',
              onTap: () {},
            ),
            const SizedBox(height: 22),
            const SectionLabel('Outras ferramentas'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _ModeTile(icon: Icons.videocam_outlined, title: 'Estabilizar vídeo', hint: 'Um vídeo mais parado', accent: LunarColors.lunarPearl, onTap: () {})),
              const SizedBox(width: 12),
              Expanded(child: _ModeTile(icon: Icons.palette_outlined, title: 'Lua Mineral', hint: 'Realçar a cor', accent: LunarColors.lunarGold, onTap: () {})),
            ]),
            const SizedBox(height: 26),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SectionLabel('Projetos recentes'),
              TextButton(onPressed: () {}, child: const Text('Ver todos')),
            ]),
            const SizedBox(height: 10),
            for (final e in mock) Padding(padding: const EdgeInsets.only(bottom: 10), child: ProjectTile(entry: e)),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho de marca: glifo de lua + wordmark "Lunar"(bold) "Stack"(regular).
class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _MoonMark(size: 30),
        const SizedBox(width: 12),
        const Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'Lunar',
                style: TextStyle(color: LunarColors.mist100, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4),
              ),
              TextSpan(
                text: 'Stack',
                style: TextStyle(color: LunarColors.mist300, fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: -0.4),
              ),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: LunarColors.obs800,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: LunarColors.border),
          ),
          child: Text('astrofoto', style: monoStyle(size: 11, color: LunarColors.mist500, weight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _MoonMark extends StatelessWidget {
  const _MoonMark({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MoonPainter());
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 2;
    final r = size.width * 0.46;
    // halo sutil
    canvas.drawCircle(Offset(c, c), r * 1.28,
        Paint()..shader = RadialGradient(colors: [LunarColors.orbitBlue.withValues(alpha: 0.22), LunarColors.orbitBlue.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(c, c), radius: r * 1.28)));
    // disco (crescente): pérola menos um recorte
    final disc = Path()..addOval(Rect.fromCircle(center: Offset(c, c), radius: r));
    final cut = Path()..addOval(Rect.fromCircle(center: Offset(c + r * 0.55, c - r * 0.2), radius: r * 0.92));
    canvas.drawPath(Path.combine(PathOperation.difference, disc, cut), Paint()..color = LunarColors.lunarPearl..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) => false;
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.icon, required this.title, required this.description, required this.onTap});
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [LunarColors.orbitBlue.withValues(alpha: 0.18), LunarColors.orbitBlue.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LunarColors.orbitBlue.withValues(alpha: 0.45)),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: LunarColors.orbitBlue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: LunarColors.orbitBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: LunarColors.orbitBlue, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.icon, required this.title, required this.hint, required this.accent, required this.onTap});
  final IconData icon;
  final String title;
  final String hint;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AstroCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(hint, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _EmptyRecents extends StatelessWidget {
  const _EmptyRecents();
  @override
  Widget build(BuildContext context) {
    return DottedPanel(
      child: Row(
        children: [
          const _MoonMark(size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Nenhum projeto ainda. Importe um vídeo ou fotos da Lua para começar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

