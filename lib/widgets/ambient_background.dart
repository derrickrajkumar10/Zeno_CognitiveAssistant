import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';

class AmbientBackground extends ConsumerStatefulWidget {
  final Widget child;
  const AmbientBackground({required this.child, super.key});

  @override
  ConsumerState<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends ConsumerState<AmbientBackground> {
  List<Color> _prevColors = AppTheme.ambientGradient(70);

  @override
  Widget build(BuildContext context) {
    final score = ref.watch(cogniPulseProvider);
    final targetColors = AppTheme.ambientGradient(score);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeInOut,
      onEnd: () => _prevColors = targetColors,
      builder: (_, t, child) {
        final interpolated = List.generate(
          targetColors.length,
          (i) => Color.lerp(_prevColors[i], targetColors[i], t)!,
        );
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: interpolated,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
