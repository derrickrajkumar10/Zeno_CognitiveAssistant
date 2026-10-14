import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zeno/models/mochi_state.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/providers/mochi_personality_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/widgets/mochi_dialogue_bubble.dart';
import 'package:zeno/widgets/mochi_widget.dart';
import 'package:zeno/widgets/particle_overlay.dart';
import 'package:zeno/screens/games/wave_sync_game.dart';
import 'package:zeno/screens/games/focus_flicker_game.dart';
import 'package:zeno/screens/games/memory_garden_game.dart';
import 'package:zeno/screens/games/bubble_drift_game.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final personality = ref.watch(mochiPersonalityProvider);
    final score = state.cogniPulseScore;
    final pad = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // Main scrollable content
        SingleChildScrollView(
          padding: EdgeInsets.only(
            top: pad.top + AppTheme.lg,
            left: AppTheme.lg,
            right: AppTheme.lg,
            bottom: pad.bottom + 100, // room for floating nav
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ────────────────────────────────────────────
              Text(
                '${_greeting()},',
                style:
                    AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),
              const SizedBox(height: 2),
              Text(
                state.user.name,
                style: AppTheme.displayMedium,
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms)
                  .slideY(begin: -0.1),

              const SizedBox(height: AppTheme.xl),

              // ── Mochi area ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    const MochiDialogueBubble(),
                    const SizedBox(height: AppTheme.md),
                    const MochiWidget(size: 180, showCrown: true)
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 200.ms)
                        .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: 600.ms,
                            curve: Curves.easeOutBack),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.xl),

              // ── CogniPulse summary card ─────────────────────────────
              GlassCard(
                child: Row(
                  children: [
                    // Score ring
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 4,
                              backgroundColor: AppTheme.surfaceBorder,
                              valueColor: AlwaysStoppedAnimation(
                                _scoreColor(score),
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            '$score',
                            style: AppTheme.displaySmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CogniPulse',
                            style: AppTheme.headlineMed,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                personality.mood.label,
                                style: AppTheme.bodySmall.copyWith(
                                  color: _scoreColor(score),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _DeltaChip(delta: state.scoreDelta),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textTertiary,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideY(begin: 0.05),

              const SizedBox(height: AppTheme.md),

              // ── Quick actions ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.favorite_rounded,
                      label: 'Start Scan',
                      color: AppTheme.accent,
                      onTap: () => context.go('/scan'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Daily Quest',
                      color: AppTheme.primaryLight,
                      onTap: () {},
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideY(begin: 0.05),

              const SizedBox(height: AppTheme.lg),

              // ── Streak banner ───────────────────────────────────────
              // ── Mochi game suggestion ────────────────────────────
              _MochiGameSuggestion(
                score: score,
                stressIndex: state.weekReadings.last.stressIndex / 100,
                focusScore: state.weekReadings.last.focusLevel / 100,
                moodScore: state.weekReadings.last.moodScore / 100,
              ),
              const SizedBox(height: AppTheme.md),

              if (state.user.currentStreak > 0)
                GlassCard(
                  tint: AppTheme.primarySoft.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🔥', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: AppTheme.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.user.currentStreak}-day streak',
                              style: AppTheme.headlineMed.copyWith(
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              'Keep checking in to grow your streak',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 500.ms)
                    .slideY(begin: 0.05),
            ],
          ),
        ),

        // ── Particle overlay (thriving mood only) ──────────────────
        if (score >= 80) const ParticleOverlay(),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.mochiThriving;
    if (score >= 55) return AppTheme.mochiBalanced;
    if (score >= 30) return AppTheme.mochiDrifting;
    return AppTheme.mochiStruggling;
  }
}

class _DeltaChip extends StatelessWidget {
  final int delta;
  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (positive ? AppTheme.success : AppTheme.error)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: positive ? AppTheme.success : AppTheme.error,
          ),
          const SizedBox(width: 3),
          Text(
            '${positive ? "+" : ""}$delta',
            style: AppTheme.caption.copyWith(
              color: positive ? AppTheme.success : AppTheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: AppTheme.headlineMed,
            ),
          ),
        ],
      ),
    );
  }
}

class _MochiGameSuggestion extends StatelessWidget {
  final int score;
  final double stressIndex;
  final double focusScore;
  final double moodScore;

  const _MochiGameSuggestion({
    required this.score,
    required this.stressIndex,
    required this.focusScore,
    required this.moodScore,
  });

  ({String title, String message, IconData icon, Widget game}) _suggestion() {
    if (stressIndex > 0.7 || score < 30) {
      return (
        title: 'Wave Sync',
        message: 'Mochi thinks some breathing would help right now',
        icon: Icons.waves_rounded,
        game: const WaveSyncGame(),
      );
    }
    if (focusScore < 0.3) {
      return (
        title: 'Focus Flicker',
        message: 'Mochi noticed your focus could use a boost',
        icon: Icons.visibility_rounded,
        game: const FocusFlickerGame(),
      );
    }
    if (moodScore < 0.4) {
      return (
        title: 'Memory Garden',
        message: "Let's plant some memories together",
        icon: Icons.local_florist_rounded,
        game: const MemoryGardenGame(),
      );
    }
    return (
      title: 'Bubble Drift',
      message: 'Mochi wants to play! Pop some bubbles?',
      icon: Icons.bubble_chart_rounded,
      game: const BubbleDriftGame(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _suggestion();
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => s.game),
        );
      },
      child: GlassCard(
        tint: AppTheme.accentSoft.withValues(alpha: 0.5),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(s.icon, color: AppTheme.accent, size: 22),
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: AppTheme.headlineMed),
                  const SizedBox(height: 2),
                  Text(s.message, style: AppTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded,
                color: AppTheme.accent, size: 24),
          ],
        ),
      ),
    );
  }
}
