import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/ambient_background.dart';

class ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ScaffoldWithNav({required this.shell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AmbientBackground(child: shell),
      bottomNavigationBar: _ZenoBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _ZenoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _ZenoBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: Color(0xFFD4E4D4), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.home_rounded,     label: 'Home',     index: 0, current: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.bolt_rounded,     label: 'Quests',   index: 1, current: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.insights_rounded, label: 'Insights', index: 2, current: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.radar_rounded,    label: 'Scan',     index: 3, current: currentIndex, onTap: onTap),
                  _NavItem(icon: Icons.person_rounded,   label: 'Profile',  index: 4, current: currentIndex, onTap: onTap),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (_, constraints) {
                const tabCount = 5;
                final tabWidth = constraints.maxWidth / tabCount;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(
                    left: currentIndex * tabWidth + tabWidth * 0.25,
                    right: (tabCount - currentIndex - 1) * tabWidth + tabWidth * 0.25,
                  ),
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: selected
                ? BoxDecoration(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  )
                : null,
            child: Icon(
              icon,
              color: selected ? AppTheme.primaryAccent : AppTheme.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: selected ? AppTheme.primaryAccent : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
