import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: TfColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: CustomPaint(painter: _AmbientPainter())),
          child,
        ],
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x1F2FD597), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.1),
          radius: size.width * 0.5));
    canvas.drawRect(Offset.zero & size, glow);

    final cyan = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x1428B7D8), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.05, size.height * 0.62),
          radius: size.width * 0.45));
    canvas.drawRect(Offset.zero & size, cyan);

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.018)
      ..strokeWidth = 0.6;
    const spacing = 46.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final random = math.Random(19);
    final dust = Paint();
    for (var i = 0; i < 42; i++) {
      dust.color =
          Colors.white.withValues(alpha: 0.02 + random.nextDouble() * 0.05);
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        random.nextDouble() * 1.2 + 0.3,
        dust,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
