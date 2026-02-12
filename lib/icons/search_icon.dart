import 'package:flutter/material.dart';

class SearchIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SearchIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SearchIconPainter(color: color),
    );
  }
}

class _SearchIconPainter extends CustomPainter {
  final Color color;

  _SearchIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    // Search circle
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.4),
      size.width * 0.28,
      paint,
    );

    // Search handle
    final handlePath = Path()
      ..moveTo(size.width * 0.6, size.height * 0.6)
      ..lineTo(size.width * 0.85, size.height * 0.85);
    canvas.drawPath(handlePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}