import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

/// Self-reported mood check-in (15% of CogniPulse in the PRD).
class QuickMoodLog extends ConsumerWidget {
  const QuickMoodLog({super.key});

  static const _emojis = ['😫', '😔', '😐', '🙂', '🌟'];
  static const _labels = ['Struggling', 'Drifting', 'Okay', 'Balanced', 'Thriving'];

  /// The 0–100 value each choice logs.
  static const values = [10, 30, 50, 70, 90];

  Color _color(int index) {
    switch (index) {
      case 0:
        return AppTheme.mochiStruggling;
      case 1:
        return AppTheme.mochiDrifting;
      case 2:
        return AppTheme.textSecondary;
      case 3:
        return AppTheme.mochiBalanced;
      default:
        return AppTheme.mochiThriving;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(appStateProvider.select((s) => s.todaysMood));
    final selected = mood == null ? -1 : values.indexOf(mood);

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.md),
      tint: selected != -1 ? _color(selected).withValues(alpha: 0.05) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('How are you feeling?', style: AppTheme.headlineMed),
              if (selected != -1)
                Text(
                  _labels[selected],
                  style: AppTheme.labelSmall.copyWith(
                    color: _color(selected),
                    fontWeight: FontWeight.w600,
                  ),
                ).animate(key: ValueKey(selected)).fadeIn().scale(),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_emojis.length, (index) {
              final isSelected = index == selected;
              final isDimmed = selected != -1 && !isSelected;

              return Semantics(
                button: true,
                label: 'Log mood: ${_labels[index]}',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(appStateProvider.notifier).logMood(values[index]);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? _color(index).withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? _color(index).withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: AnimatedScale(
                      scale: isSelected ? 1.4 : (isDimmed ? 0.8 : 1.1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: isDimmed ? 0.4 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _emojis[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            selected == -1
                ? 'Your answer counts toward today\'s CogniPulse.'
                : 'Logged. Tap another face to change it.',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}
