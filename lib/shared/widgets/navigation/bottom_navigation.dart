import 'package:flutter/material.dart';
import '../../../icons/social_icon.dart';
import '../../../icons/cart_icon.dart';
import '../../../icons/map_icon.dart';
import '../../../icons/profile_icon.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withOpacity(0.5);
    const activeColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: SocialIcon(
                  size: 26,
                  color: currentIndex == 0 ? activeColor : inactiveColor,
                ),
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: CartIcon(
                  size: 26,
                  color: currentIndex == 1 ? activeColor : inactiveColor,
                ),
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: MapIcon(
                  size: 26,
                  color: currentIndex == 2 ? activeColor : inactiveColor,
                ),
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: ProfileIcon(
                  size: 26,
                  color: currentIndex == 3 ? activeColor : inactiveColor,
                ),
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedScale(
          scale: isActive ? 1.0 : 0.9,
          duration: const Duration(milliseconds: 200),
          child: icon,
        ),
      ),
    );
  }
}