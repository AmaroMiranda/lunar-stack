import 'package:flutter/material.dart';

/// Comparador antes/depois com slider (spec seção 36) — o ganho visual
/// precisa ser percebido rapidamente, não só lido em texto.
class AstroBeforeAfterViewer extends StatefulWidget {
  const AstroBeforeAfterViewer({
    super.key,
    required this.before,
    required this.after,
    this.height = 280,
  });

  final Widget before;
  final Widget after;
  final double height;

  @override
  State<AstroBeforeAfterViewer> createState() => _AstroBeforeAfterViewerState();
}

class _AstroBeforeAfterViewerState extends State<AstroBeforeAfterViewer> {
  double _dividerFraction = 0.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final dividerX = width * _dividerFraction;
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dividerFraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
                });
              },
              onTapUp: (details) {
                setState(() {
                  _dividerFraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.after,
                  ClipRect(
                    clipper: _LeftClipper(dividerX),
                    child: widget.before,
                  ),
                  Positioned(
                    left: dividerX - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  Positioned(
                    left: dividerX - 16,
                    top: widget.height / 2 - 16,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.swap_horiz, size: 18, color: Colors.white),
                    ),
                  ),
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: _CornerLabel(text: 'Antes'),
                  ),
                  const Positioned(
                    right: 10,
                    top: 10,
                    child: _CornerLabel(text: 'Depois'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CornerLabel extends StatelessWidget {
  const _CornerLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.dividerX);
  final double dividerX;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, dividerX, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) => oldClipper.dividerX != dividerX;
}
