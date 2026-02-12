import 'package:flutter/material.dart';

class CartIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CartIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CartIconPainter(color: color),
    );
  }
}

class _CartIconPainter extends CustomPainter {
  final Color color;

  _CartIconPainter({required this.color});

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

    // Cart handle (curved line at top)
    final handlePath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.15)
      ..lineTo(size.width * 0.2, size.height * 0.08)
      ..arcToPoint(
        Offset(size.width * 0.45, size.height * 0.08),
        radius: Radius.circular(size.width * 0.12),
      )
      ..lineTo(size.width * 0.45, size.height * 0.15);
    canvas.drawPath(handlePath, paint);

    // Cart body (trapezoid shape)
    final bodyPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.25)
      ..lineTo(size.width * 0.25, size.height * 0.65)
      ..lineTo(size.width * 0.85, size.height * 0.65)
      ..lineTo(size.width * 0.9, size.height * 0.25)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Left wheel
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.85),
      size.width * 0.08,
      fillPaint,
    );

    // Right wheel
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.85),
      size.width * 0.08,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}