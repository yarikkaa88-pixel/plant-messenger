import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/plant_colors.dart';

class PlantBackground extends StatelessWidget {
  const PlantBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PlantColors.lime, PlantColors.limeLight],
            ),
          ),
        ),
        const Positioned.fill(child: _PatternLayer()),
        child,
      ],
    );
  }
}

class _PatternLayer extends StatelessWidget {
  const _PatternLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _PlantPatternPainter()),
    );
  }
}

class _PlantPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PlantColors.pattern
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const spacing = 72.0;
    for (var y = -spacing; y < size.height + spacing; y += spacing) {
      for (var x = -spacing; x < size.width + spacing; x += spacing) {
        final offset = Offset(x + (y % (spacing * 2)) * 0.25, y);
        _drawX(canvas, offset, 14, paint);
        _drawPlanet(canvas, offset + const Offset(36, 28), paint);
      }
    }
  }

  void _drawX(Canvas canvas, Offset center, double half, Paint paint) {
    canvas.drawLine(
      center - Offset(half, half),
      center + Offset(half, half),
      paint,
    );
    canvas.drawLine(
      center - Offset(-half, half),
      center + Offset(half, -half),
      paint,
    );
  }

  void _drawPlanet(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 10, paint);
    final ring = Path()
      ..addOval(
        Rect.fromCenter(
          center: center,
          width: 28,
          height: 10,
        ),
      );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 6);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(ring, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
