import 'package:flutter/material.dart';

/// Cadre de guidage animé pour centrer la feuille dans la caméra
class DetectionFrame extends StatefulWidget {
  const DetectionFrame({super.key});

  @override
  State<DetectionFrame> createState() => _DetectionFrameState();
}

class _DetectionFrameState extends State<DetectionFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return CustomPaint(
          painter: _FramePainter(opacity: _pulseAnim.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFF1D9E75);
    const cornerLength = 28.0;
    const strokeWidth = 3.5;
    const margin = 60.0;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const left = margin;
    final top = size.height * 0.2;
    final right = size.width - margin;
    final bottom = size.height * 0.8;

    // Coin haut-gauche
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);

    // Coin haut-droit
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), paint);

    // Coin bas-gauche
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);

    // Coin bas-droit
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.opacity != opacity;
}
