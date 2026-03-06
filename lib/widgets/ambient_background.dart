import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

/// Ambient background that smoothly transitions gradient based on CogniPulse score.
class AmbientBackground extends ConsumerWidget {
  final Widget child;
  const AmbientBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(cogniPulseProvider);
    final colors = AppTheme.ambientGradient(score);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}
