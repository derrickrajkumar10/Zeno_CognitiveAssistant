import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onComplete;
  final int index;

  const QuestCard({
    super.key,
    required this.quest,
    required this.onComplete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final completed = quest.status == QuestStatus.completed;

    return GlassCard(
      tint: completed
          ? AppTheme.primarySoft.withValues(alpha: 0.5)
          : AppTheme.surfaceGlass,
      borderColor: completed
          ? AppTheme.primaryLight.withValues(alpha: 0.4)
          : AppTheme.surfaceBorder,
      margin: const EdgeInsets.only(bottom: AppTheme.sm),
      onTap: completed
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onComplete();
            },
      child: Row(
        children: [
          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: completed
                  ? AppTheme.primaryLight.withValues(alpha: 0.15)
                  : AppTheme.surfaceGlassDim,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(quest.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: AppTheme.md),

          // Title + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: AppTheme.headlineMed.copyWith(
                    decoration: completed ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.textTertiary,
                    color: completed
                        ? AppTheme.textTertiary
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quest.duration,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),

          // XP badge / checkmark
          if (completed)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${quest.xpReward} XP',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideY(
        begin: 0.05,
        duration: 400.ms,
        delay: (index * 80).ms,
        curve: Curves.easeOutCubic);
  }
}
