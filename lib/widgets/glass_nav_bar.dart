import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeno/theme/app_theme.dart';

/// A premium frosted-glass bottom navigation bar that floats over content.
///
/// Features:
/// - Backdrop blur with semi-transparent fill
/// - Active tab has animated glowing dot indicator
/// - iOS-native haptic feedback on tap
/// - Floats above content with rounded corners and safe area respect
class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.auto_awesome_rounded, label: 'Quests'),
    _NavItem(icon: Icons.favorite_rounded, label: 'Scan'),
    _NavItem(icon: Icons.insights_rounded, label: 'Insights'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppTheme.md,
      right: AppTheme.md,
      bottom: MediaQuery.of(context).padding.bottom + AppTheme.sm,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.navBarBlur,
            sigmaY: AppTheme.navBarBlur,
          ),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xDDFAF9F6), // 87% card surface
              borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
              border: Border.all(
                color: AppTheme.surfaceBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x08000000),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_items.length, (i) {
                final active = i == currentIndex;
                return _NavBarButton(
                  item: _items[i],
                  active: active,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavBarButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Icon(
                item.icon,
                size: active ? 24 : 22,
                color: active ? AppTheme.primary : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            // Glowing dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: active ? 4 : 0,
              height: active ? 4 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
