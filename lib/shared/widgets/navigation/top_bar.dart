import 'package:flutter/material.dart';
import '../../../icons/search_icon.dart';
import '../../../icons/qr_icon.dart';
import '../../../icons/camera_icon.dart';
import '../../../icons/menu_icon.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onSearchPress;
  final VoidCallback? onQRPress;
  final VoidCallback? onCameraPress;
  final VoidCallback? onMenuPress;

  const TopBar({
    super.key,
    required this.title,
    this.onSearchPress,
    this.onQRPress,
    this.onCameraPress,
    this.onMenuPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF6C63FF),
            ),
          ),
          Row(
            children: [
              if (onSearchPress != null)
                IconButton(
                  onPressed: onSearchPress,
                  icon: const SearchIcon(size: 28, color: Color(0xFF6C63FF)),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              if (onSearchPress != null && (onQRPress != null || onCameraPress != null))
                const SizedBox(width: 8),
              if (onQRPress != null)
                IconButton(
                  onPressed: onQRPress,
                  icon: const QRIcon(size: 28, color: Color(0xFF6C63FF)),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              if (onQRPress != null && onCameraPress != null)
                const SizedBox(width: 8),
              if (onCameraPress != null)
                IconButton(
                  onPressed: onCameraPress,
                  icon: const CameraIcon(size: 28, color: Color(0xFF6C63FF)),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              if (onMenuPress != null)
                IconButton(
                  onPressed: onMenuPress,
                  icon: const MenuIcon(size: 28, color: Color(0xFF6C63FF)),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}