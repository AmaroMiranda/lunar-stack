import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Visualizador em tela cheia sobre preto absoluto — a foto é o único
/// elemento (Observatory Dark). Pinça/duplo-toque para zoom, arrasto para
/// varrer os detalhes em resolução plena. Aberto por um toque na imagem final.
class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.file,
    this.caption,
  });

  final File file;
  final String? caption;

  static Future<void> open(
    BuildContext context, {
    required File file,
    String? caption,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) =>
            FullscreenImageViewer(file: file, caption: caption),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  final _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
      return;
    }
    final pos = _doubleTapDetails?.localPosition;
    if (pos == null) return;
    const scale = 2.6;
    _controller.value = Matrix4.identity()
      ..translateByDouble(-pos.dx * (scale - 1), -pos.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapDetails = d,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 8,
                child: Center(
                  child: Image.file(widget.file, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          if (widget.caption != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    widget.caption!,
                    style: monoStyle(
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
