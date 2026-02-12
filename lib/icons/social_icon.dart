import 'package:flutter/material.dart';

class SocialIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SocialIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SocialIconPainter(color: color),
    );
  }
}

class _SocialIconPainter extends CustomPainter {
  final Color color;

  _SocialIconPainter({required this.color});

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

    // Profile circle on the left
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.25),
      size.width * 0.14,
      paint,
    );

    // Content lines on the right
    final lineHeight = size.width * 0.08;
    final lineStartX = size.width * 0.42;
    
    // First line (longest)
    final line1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        lineStartX,
        size.height * 0.12,
        size.width * 0.53,
        lineHeight,
      ),
      Radius.circular(lineHeight / 2),
    );
    canvas.drawRRect(line1, fillPaint);

    // Second line (longest)
    final line2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        lineStartX,
        size.height * 0.28,
        size.width * 0.53,
        lineHeight,
      ),
      Radius.circular(lineHeight / 2),
    );
    canvas.drawRRect(line2, fillPaint);

    // Third line (shorter)
    final line3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        lineStartX,
        size.height * 0.44,
        size.width * 0.35,
        lineHeight,
      ),
      Radius.circular(lineHeight / 2),
    );
    canvas.drawRRect(line3, fillPaint);

    // Engagement icons at bottom
    final iconSize = size.width * 0.12;
    final bottomY = size.height * 0.75;

    // Heart icon (simple)
    canvas.drawCircle(
      Offset(size.width * 0.2, bottomY),
      iconSize * 0.5,
      paint,
    );

    // Comment icon (simple)
    canvas.drawCircle(
      Offset(size.width * 0.5, bottomY),
      iconSize * 0.5,
      paint,
    );

    // Share icon (simple)
    canvas.drawCircle(
      Offset(size.width * 0.8, bottomY),
      iconSize * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}