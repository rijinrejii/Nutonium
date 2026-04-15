import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../icons/camera_icon.dart';
import '../../../icons/menu_icon.dart';
import '../../../icons/qr_icon.dart';
import '../../../icons/search_icon.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.onSearchPress,
    this.onQrPress,
    this.onCameraPress,
    this.onMenuPress,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onSearchPress;
  final VoidCallback? onQrPress;
  final VoidCallback? onCameraPress;
  final VoidCallback? onMenuPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.forestDeep, AppPalette.forest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppPalette.forest.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onSearchPress != null)
                _ActionPill(
                  onTap: onSearchPress!,
                  child: const SearchIcon(size: 22, color: Colors.white),
                ),
              if (onQrPress != null)
                _ActionPill(
                  onTap: onQrPress!,
                  child: const QRIcon(size: 22, color: Colors.white),
                ),
              if (onCameraPress != null)
                _ActionPill(
                  onTap: onCameraPress!,
                  child: const CameraIcon(size: 22, color: Colors.white),
                ),
              if (onMenuPress != null)
                _ActionPill(
                  onTap: onMenuPress!,
                  child: const MenuIcon(size: 22, color: Colors.white),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}
