import 'package:flutter/material.dart';

class MapIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MapIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MapIconPainter(color: color),
    );
  }
}

class _MapIconPainter extends CustomPainter {
  final Color color;

  _MapIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Pin top circle
    final pinPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..arcToPoint(
        Offset(size.width * 0.5, size.height * 0.5),
        radius: Radius.circular(size.width * 0.25),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(size.width * 0.5, size.height * 0.1),
        radius: Radius.circular(size.width * 0.25),
        clockwise: false,
      );
    canvas.drawPath(pinPath, paint);

    // Pin point (triangle)
    final pointPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.85)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height * 0.5)
      ..close();
    canvas.drawPath(pointPath, fillPaint);

    // Inner dot
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      size.width * 0.1,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}