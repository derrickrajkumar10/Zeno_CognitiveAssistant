import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/services/ollama_service.dart';
import 'package:zeno/theme/app_theme.dart';

class MochiDialogueBubble extends ConsumerWidget {
  const MochiDialogueBubble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(mochiDialogueProvider);
    final loading = ref.watch(mochiLoadingProvider);

    return AnimatedSwitcher(
      duration: 400.ms,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position:
              Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(line),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
            bottomLeft: Radius.circular(6),
          ),
          border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE8E5F0))),
        ),
        child: loading
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryAccent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Mochi is thinking…',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ])
            : Text(
                line,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
      ),
    );
  }
}
