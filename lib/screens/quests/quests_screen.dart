import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/mock_data.dart';
import 'package:zeno/models/quest.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/mochi_notification_banner.dart';
import 'package:zeno/widgets/quest_card.dart';

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider);
    final appState = ref.watch(appStateProvider);
    final completedCount =
        quests.where((q) => q.status == QuestStatus.completed).length;
    final xpProgress = (appState.totalXpToday / 300).clamp(0.0, 1.0);

    ref.listen(questsProvider, (prev, next) {
      if (prev == null) return;
      final justCompleted = next.where((q) =>
          q.status == QuestStatus.completed &&
          prev.any(
              (p) => p.id == q.id && p.status != QuestStatus.completed));
      for (final _ in justCompleted) {
        final msg = MockData.questCompleteDialogue[
            DateTime.now().millisecondsSinceEpoch %
                MockData.questCompleteDialogue.length];
        MochiNotificationBanner.show(context, msg);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Quests',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.warmAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🔥 5 day streak',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warmAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFFE8E5F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's XP",
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        Text(
                          '${appState.totalXpToday} / 300 XP',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: xpProgress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) => LinearProgressIndicator(
                          value: val,
                          backgroundColor:
                              const Color(0xFFE8E5F0),
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primaryAccent),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedCount of ${quests.length} quests completed',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              ...quests.asMap().entries.map((e) => QuestCard(quest: e.value, index: e.key)),
            ],
          ),
        ),
      ),
    );
  }
}
