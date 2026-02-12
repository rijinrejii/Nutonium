import 'package:flutter/material.dart';

class MenuIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MenuIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MenuIconPainter(color: color),
    );
  }
}

class _MenuIconPainter extends CustomPainter {
  final Color color;

  _MenuIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw circle outline
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.45,
      paint,
    );

    // Draw three horizontal lines
    final lineWidth = size.width * 0.4;
    final lineHeight = size.width * 0.08;
    final centerX = size.width / 2;
    final spacing = size.height * 0.12;

    // First line
    final line1 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.35),
        width: lineWidth,
        height: lineHeight,
      ),
      Radius.circular(lineHeight / 2),
    );
    canvas.drawRRect(line1, fillPaint);

    // Second line
    final line2 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.5),
        width: lineWidth,
        height: lineHeight,
      ),
      Radius.circular(lineHeight / 2),
    );
    canvas.drawRRect(line2, fillPaint);

    // Third line
    final line3 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.65),
        width: lineWidth,
        height: lineHeight,
      ),
      Radius.circular(lineHeight / 2),
    );
    canvas.drawRRect(line3, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}