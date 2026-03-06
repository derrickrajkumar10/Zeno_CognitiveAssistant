import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/widgets/mochi_widget.dart';

class PostGameScreen extends ConsumerWidget {
  final String gameTitle;
  final int score;
  final int xpEarned;
  final int levelReached;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const PostGameScreen({
    super.key,
    required this.gameTitle,
    required this.score,
    required this.xpEarned,
    required this.levelReached,
    required this.onPlayAgain,
    required this.onExit,
  });

  String _mochiReaction(MochiMoodState mood, int score) {
    if (score >= 80) return "Mochi is doing a happy wiggle! You crushed it! 🌟";
    if (score >= 60) return "Nice one! Mochi's impressed with that focus.";
    if (score >= 40) return "Solid effort. Mochi saw you improving mid-game.";
    return "Hey, you showed up. That's what matters to Mochi 🐾";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(mochiMoodProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            children: [
              const Spacer(),
              // Mochi reaction
              const MochiWidget(size: 120, interactive: false),
              const SizedBox(height: AppTheme.md),
              Text(
                _mochiReaction(mood, score),
                style: AppTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.xl),
              // Stats card
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.lg),
                  child: Column(
                    children: [
                      Text(gameTitle, style: AppTheme.headlineLarge),
                      const SizedBox(height: AppTheme.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Stat(label: 'Score', value: '$score%'),
                          _Stat(label: 'Level', value: '$levelReached'),
                          _Stat(label: 'XP', value: '+$xpEarned'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Play Again
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onPlayAgain();
                  },
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(height: AppTheme.sm),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onExit();
                },
                child: Text(
                  'Back to Playroom',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: AppTheme.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.displaySmall.copyWith(color: AppTheme.primary)),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.caption),
      ],
    );
  }
}
