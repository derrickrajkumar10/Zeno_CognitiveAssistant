import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/games/focus_flicker_game.dart';
import 'package:zeno/screens/games/memory_garden_game.dart';
import 'package:zeno/screens/games/wave_sync_game.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/widgets/mochi_notification_banner.dart';
import 'package:zeno/widgets/quest_card.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  final _bannerKey = GlobalKey<MochiNotificationBannerState>();

  static const _gameQuestMap = {
    'breathing': WaveSyncGame(),
    'focus_quest': FocusFlickerGame(),
    'memory_quest': MemoryGardenGame(),
  };

  void _handleQuestComplete(String questId) {
    final game = _gameQuestMap[questId];
    if (game != null) {
      Navigator.of(context, rootNavigator: true)
          .push<bool>(MaterialPageRoute(builder: (_) => game))
          .then((completed) {
        if (!mounted) {
          return;
        }
        if (completed != true) {
          _bannerKey.currentState?.show(
            'Mochi kept the quest open. Finish the game to claim the XP.',
          );
          return;
        }
        ref.read(appStateProvider.notifier).completeQuest(questId);
        _bannerKey.currentState?.show(
          "Quest complete! Mochi's proud of you 🌱",
        );
      });
      return;
    }

    ref.read(appStateProvider.notifier).completeQuest(questId);
    final state = ref.read(appStateProvider);
    final questName = state.quests.firstWhere((quest) => quest.id == questId).title;
    _bannerKey.currentState?.show(
      "Great job completing $questName! Here's to feeling better. 🌱",
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final quests = state.quests;
    final completedCount =
        quests.where((quest) => quest.status.name == 'completed').length;
    final pad = MediaQuery.of(context).padding;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            top: pad.top + AppTheme.lg,
            left: AppTheme.lg,
            right: AppTheme.lg,
            bottom: pad.bottom + 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Quests', style: AppTheme.displayMedium)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.1),
              const SizedBox(height: AppTheme.sm),
              Text(
                '$completedCount of ${quests.length} completed',
                style: AppTheme.bodySmall,
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
              const SizedBox(height: AppTheme.lg),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Today\'s XP', style: AppTheme.headlineMed),
                        Text(
                          '${state.totalXpToday} XP',
                          style: AppTheme.headlineMed.copyWith(
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (state.totalXpToday / 300).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppTheme.surfaceGlassDim,
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.primaryLight),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Goal: 300 XP', style: AppTheme.labelSmall),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: AppTheme.lg),
              ...List.generate(quests.length, (index) {
                return QuestCard(
                  quest: quests[index],
                  index: index,
                  onComplete: () => _handleQuestComplete(quests[index].id),
                );
              }),
              const SizedBox(height: AppTheme.md),
              if (state.user.currentStreak > 0)
                Center(
                  child: Text(
                    '${state.user.currentStreak}-day streak active',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
            ],
          ),
        ),
        MochiNotificationBanner(key: _bannerKey),
      ],
    );
  }
}
