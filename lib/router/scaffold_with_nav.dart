import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/widgets/ambient_background.dart';
import 'package:zeno/widgets/glass_nav_bar.dart';

class ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ScaffoldWithNav({required this.shell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AmbientBackground(
        child: Stack(
          children: [
            // Main content — extends behind nav bar
            Positioned.fill(
              child: shell,
            ),
            // Floating glass nav bar
            GlassNavBar(
              currentIndex: shell.currentIndex,
              onTap: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
            ),
          ],
        ),
      ),
    );
  }
}
