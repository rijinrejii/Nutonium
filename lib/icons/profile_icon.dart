import 'package:flutter/material.dart';

class ProfileIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ProfileIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ProfileIconPainter(color: color),
    );
  }
}

class _ProfileIconPainter extends CustomPainter {
  final Color color;

  _ProfileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Head circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.3),
      size.width * 0.18,
      paint,
    );

    // Body (semicircle/arc at bottom)
    final bodyPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.9)
      ..arcToPoint(
        Offset(size.width * 0.85, size.height * 0.9),
        radius: Radius.circular(size.width * 0.35),
        largeArc: false,
      );
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}