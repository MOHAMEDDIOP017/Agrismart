import 'package:flutter/material.dart';

/// Animation de ligne de scan IA — balaie de haut en bas en boucle
class ScanLineAnimation extends StatefulWidget {
  const ScanLineAnimation({required this.child, super.key});

  final Widget child;

  @override
  State<ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return CustomPaint(
              painter: ScanLinePainter(progress: _animation.value),
              child: const SizedBox.expand(),
            );
          },
        ),
      ],
    );
  }
}

/// Peintre de la ligne de scan avec effet de lueur
class ScanLinePainter extends CustomPainter {
  const ScanLinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Zone déjà scannée (overlay vert très transparent)
    final scannedPaint = Paint()
      ..color = const Color(0xFF1D9E75).withValues(alpha: 0.06);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, y), scannedPaint);

    // Lueur diffuse derrière la ligne
    final glowPaint = Paint()
      ..color = const Color(0xFF1D9E75).withValues(alpha: 0.25)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), glowPaint);

    // Ligne principale de scan
    final linePaint = Paint()
      ..color = const Color(0xFF1D9E75).withValues(alpha: 0.92)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
  }

  @override
  bool shouldRepaint(ScanLinePainter old) => old.progress != progress;
}
