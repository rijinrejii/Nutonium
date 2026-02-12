import 'package:flutter/material.dart';

class QRIcon extends StatelessWidget {
  final double size;
  final Color color;

  const QRIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final cornerSize = size * 0.25;
    final borderWidth = size * 0.08;
    final barWidth = size * 0.08;
    final barHeight = size * 0.6;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top Left Corner
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: cornerSize,
              height: cornerSize,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: borderWidth),
                  left: BorderSide(color: color, width: borderWidth),
                ),
              ),
            ),
          ),
          // Top Right Corner
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: cornerSize,
              height: cornerSize,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: borderWidth),
                  right: BorderSide(color: color, width: borderWidth),
                ),
              ),
            ),
          ),
          // Bottom Left Corner
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: cornerSize,
              height: cornerSize,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: borderWidth),
                  left: BorderSide(color: color, width: borderWidth),
                ),
              ),
            ),
          ),
          // Bottom Right Corner
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: cornerSize,
              height: cornerSize,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: borderWidth),
                  right: BorderSide(color: color, width: borderWidth),
                ),
              ),
            ),
          ),
          // Vertical Bars
          Positioned(
            top: (size - barHeight) / 2,
            left: size * 0.18,
            right: size * 0.18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                ),
                Container(
                  width: barWidth * 1.4,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(barWidth),
                  ),
                ),
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                ),
                Container(
                  width: barWidth * 1.4,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(barWidth),
                  ),
                ),
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                ),
                Container(
                  width: barWidth * 1.4,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(barWidth),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}