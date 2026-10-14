import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/games/bubble_drift_game.dart';
import 'package:zeno/screens/games/dream_sort_game.dart';
import 'package:zeno/screens/games/focus_flicker_game.dart';
import 'package:zeno/screens/games/memory_garden_game.dart';
import 'package:zeno/screens/games/mochi_says_game.dart';
import 'package:zeno/screens/games/puzzle_world_game.dart';
import 'package:zeno/screens/games/slice_calm_game.dart';
import 'package:zeno/screens/games/wave_sync_game.dart';
import 'package:zeno/services/game_repository.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';

class _GameInfo {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget Function() builder;

  const _GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.builder,
  });
}

class _RankedGame {
  final _GameInfo info;
  final DateTime? lastPlayedAt;
  final bool recommended;

  const _RankedGame({
    required this.info,
    required this.lastPlayedAt,
    required this.recommended,
  });

  bool get stale =>
      lastPlayedAt == null || DateTime.now().difference(lastPlayedAt!).inHours >= 48;
}

final _games = <_GameInfo>[
  _GameInfo(
    id: 'bubble_drift',
    title: 'Bubble Drift',
    subtitle: 'Pop bubbles before they float away',
    icon: Icons.bubble_chart_rounded,
    accentColor: AppTheme.primaryLight,
    builder: () => const BubbleDriftGame(),
  ),
  _GameInfo(
    id: 'mochi_says',
    title: 'Mochi Says',
    subtitle: 'Repeat Mochi\'s sequence',
    icon: Icons.grid_on_rounded,
    accentColor: AppTheme.accent,
    builder: () => const MochiSaysGame(),
  ),
  _GameInfo(
    id: 'wave_sync',
    title: 'Wave Sync',
    subtitle: 'Tap in rhythm with the wave',
    icon: Icons.waves_rounded,
    accentColor: AppTheme.info,
    builder: () => const WaveSyncGame(),
  ),
  _GameInfo(
    id: 'memory_garden',
    title: 'Memory Garden',
    subtitle: 'Remember where objects were',
    icon: Icons.local_florist_rounded,
    accentColor: AppTheme.success,
    builder: () => const MemoryGardenGame(),
  ),
  _GameInfo(
    id: 'slice_calm',
    title: 'Slice & Calm',
    subtitle: 'Slice golden leaves, avoid stones',
    icon: Icons.content_cut_rounded,
    accentColor: AppTheme.warning,
    builder: () => const SliceCalmGame(),
  ),
  _GameInfo(
    id: 'focus_flicker',
    title: 'Focus Flicker',
    subtitle: 'Tap matching items and adapt after flips',
    icon: Icons.visibility_rounded,
    accentColor: AppTheme.primary,
    builder: () => const FocusFlickerGame(),
  ),
  _GameInfo(
    id: 'dream_sort',
    title: 'Dream Sort',
    subtitle: 'Swipe to sort after categories invert',
    icon: Icons.sort_rounded,
    accentColor: AppTheme.mochiDrifting,
    builder: () => const DreamSortGame(),
  ),
  _GameInfo(
    id: 'puzzle_world',
    title: "Mochi's Puzzle World",
    subtitle: 'Solve sliding puzzles with escalating complexity',
    icon: Icons.extension_rounded,
    accentColor: AppTheme.mochiThriving,
    builder: () => const PuzzleWorldGame(),
  ),
];

class PlayroomScreen extends ConsumerWidget {
  const PlayroomScreen({super.key});

  String _recommendedGameId(AppState state) {
    final latestReading = state.weekReadings.last;
    if (latestReading.stressIndex / 100 >= 0.7 || state.cogniPulseScore <= 30) {
      return 'wave_sync';
    }
    if (latestReading.focusLevel / 100 < 0.3) {
      return 'focus_flicker';
    }
    if (latestReading.moodScore / 100 < 0.4) {
      return 'memory_garden';
    }
    return 'bubble_drift';
  }

  Future<List<_RankedGame>> _loadGames(String recommendedId) async {
    final repo = GameRepository();
    final rankedGames = <_RankedGame>[];

    for (final game in _games) {
      final lastPlayedAt = await repo.getLastPlayedAt('alex', game.id);
      rankedGames.add(
        _RankedGame(
          info: game,
          lastPlayedAt: lastPlayedAt,
          recommended: game.id == recommendedId,
        ),
      );
    }

    rankedGames.sort((left, right) {
      if (left.stale != right.stale) {
        return left.stale ? -1 : 1;
      }
      if (left.recommended != right.recommended) {
        return left.recommended ? -1 : 1;
      }
      return left.info.title.compareTo(right.info.title);
    });

    return rankedGames;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final recommendedId = _recommendedGameId(state);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.md,
        right: AppTheme.md,
        top: AppTheme.lg,
        bottom: 90,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mochi's Playroom", style: AppTheme.displaySmall),
          const SizedBox(height: AppTheme.xs),
          Text(
            'Your games are sorted by time away, current need, and everything else.',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: AppTheme.lg),
          Expanded(
            child: FutureBuilder<List<_RankedGame>>(
              future: _loadGames(recommendedId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sentiment_dissatisfied_rounded,
                            color: AppTheme.textSecondary,
                            size: 28,
                          ),
                          const SizedBox(height: AppTheme.sm),
                          Text(
                            'Mochi could not open the playroom yet.',
                            style: AppTheme.headlineMed,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.xs),
                          Text(
                            '${snapshot.error}',
                            style: AppTheme.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final games = snapshot.data;
                if (games == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                return ListView.separated(
                  itemCount: games.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.sm),
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return _GameCard(game: game);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final _RankedGame game;

  const _GameCard({required this.game});

  String _lastPlayedLabel() {
    if (game.lastPlayedAt == null) {
      return 'Not played yet';
    }
    final hoursAgo = DateTime.now().difference(game.lastPlayedAt!).inHours;
    if (hoursAgo >= 48) {
      return 'Ready again after ${hoursAgo}h away';
    }
    return 'Played ${hoursAgo}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context, rootNavigator: true)
            .push(MaterialPageRoute(builder: (_) => game.info.builder()));
      },
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: game.info.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadiusSm),
                ),
                child: Icon(game.info.icon, color: game.info.accentColor, size: 24),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(game.info.title, style: AppTheme.headlineMed),
                        ),
                        if (game.recommended)
                          _Badge(
                            label: 'Mochi picks',
                            background: AppTheme.accent.withValues(alpha: 0.18),
                            textColor: AppTheme.accent,
                          ),
                        if (game.stale)
                          const _Badge(
                            label: '48h+',
                            background: AppTheme.primarySoft,
                            textColor: AppTheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(game.info.subtitle, style: AppTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(_lastPlayedLabel(), style: AppTheme.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppTheme.sm),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(color: textColor),
      ),
    );
  }
}
