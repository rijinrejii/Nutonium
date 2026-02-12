import 'package:flutter/material.dart';

class CameraIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CameraIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final bodyWidth = size * 0.9;
    final bodyHeight = size * 0.68;
    final borderWidth = size * 0.08;
    final viewfinderWidth = size * 0.35;
    final viewfinderHeight = size * 0.12;
    final lensSize = size * 0.44;
    final lensInnerSize = size * 0.3;
    final flashSize = size * 0.11;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Top Viewfinder Bump
          Positioned(
            top: size * 0.05,
            child: Container(
              width: viewfinderWidth,
              height: viewfinderHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: borderWidth),
                  left: BorderSide(color: color, width: borderWidth),
                  right: BorderSide(color: color, width: borderWidth),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.08),
                  topRight: Radius.circular(size * 0.08),
                ),
              ),
            ),
          ),
          // Camera Body
          Positioned(
            top: size * 0.17,
            child: Container(
              width: bodyWidth,
              height: bodyHeight,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: borderWidth),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
              child: Center(
                child: Container(
                  width: lensSize,
                  height: lensSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: borderWidth),
                  ),
                  child: Center(
                    child: Container(
                      width: lensInnerSize,
                      height: lensInnerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: borderWidth),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Flash/Dot
          Positioned(
            top: size * 0.25,
            right: size * 0.14,
            child: Container(
              width: flashSize,
              height: flashSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}