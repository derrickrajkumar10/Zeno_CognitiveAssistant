import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/games/post_game_screen.dart';
import 'package:zeno/services/game_feature_pipeline.dart';
import 'package:zeno/services/game_repository.dart';
import 'package:zeno/services/game_signal_collector.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/ambient_background.dart';

/// Wraps a game widget with session tracking, save logic, and post-game flow.
class GameWrapper extends ConsumerStatefulWidget {
  final String gameId;
  final String gameTitle;
  final int xpReward;
  final Widget Function(GameWrapperState controller) gameBuilder;

  const GameWrapper({
    super.key,
    required this.gameId,
    required this.gameTitle,
    required this.xpReward,
    required this.gameBuilder,
  });

  @override
  ConsumerState<GameWrapper> createState() => GameWrapperState();
}

class GameWrapperState extends ConsumerState<GameWrapper> {
  final _collector = GameSignalCollector();
  final _repo = GameRepository();
  final _contributor = CogniPulseGameContributor();

  bool _showResults = false;
  bool _ending = false;
  bool _completedNaturally = false;
  int _gameScore = 0;
  int _levelReached = 0;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _collector.recordTouch(eventType: 'session_start');
  }

  void markStimulus() => _collector.markStimulus();

  void recordTouch({
    int? reactionTimeMs,
    double tapPressure = 0.5,
    Offset tapPosition = Offset.zero,
    required String eventType,
    Map<String, dynamic> gameContext = const {},
  }) {
    _collector.recordTouch(
      reactionTimeMs: reactionTimeMs,
      tapPressure: tapPressure,
      tapPosition: tapPosition,
      eventType: eventType,
      gameContext: gameContext,
    );
  }

  Future<void> endGame({
    required int score,
    required int levelReached,
    bool dropOffEarly = false,
  }) async {
    if (_ending || _showResults) {
      return;
    }

    _ending = true;
    HapticFeedback.mediumImpact();
    _gameScore = score;
    _levelReached = levelReached;
    _completedNaturally = !dropOffEarly;

    // A storage failure must never trap the player in a finished game, so
    // the results screen is shown even if saving the session fails.
    try {
      final session = await _collector.flushSession(
        gameId: widget.gameId,
        levelReached: levelReached,
        dropOffEarly: dropOffEarly,
      );
      final touchEvents = _collector.takeLastFlushedEvents();

      await _repo.saveSession(session);
      await _repo.saveTouchEvents(touchEvents);
      await _repo.updateBaseline(session.userId, widget.gameId);

      final signalScore = await _contributor.computeSignalScore(session.userId);
      if (mounted) {
        await ref.read(appStateProvider.notifier).recordGameResult(
              gameId: widget.gameId,
              xpReward: widget.xpReward,
              completed: !dropOffEarly,
              signalScore: signalScore,
            );
      }
    } catch (error, stackTrace) {
      debugPrint('GameWrapper could not save session: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (mounted) {
      setState(() => _showResults = true);
    }
    _ending = false;
  }

  Future<void> _handleBackPress() async {
    if (_showResults) {
      Navigator.of(context).pop(_completedNaturally);
      return;
    }
    await endGame(
      score: _gameScore,
      levelReached: _levelReached,
      dropOffEarly: true,
    );
  }

  void _playAgain() {
    setState(() {
      _showResults = false;
      _ending = false;
      _completedNaturally = false;
      _gameScore = 0;
      _levelReached = 0;
    });
    _startSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return PopScope<bool>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            Navigator.of(context).pop(_completedNaturally);
          }
        },
        child: PostGameScreen(
          gameTitle: widget.gameTitle,
          score: _gameScore,
          xpEarned: _completedNaturally ? widget.xpReward : 0,
          levelReached: _levelReached,
          onPlayAgain: _playAgain,
          onExit: () => Navigator.of(context).pop(_completedNaturally),
        ),
      );
    }

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: AmbientBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.md,
                    vertical: AppTheme.sm,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _handleBackPress,
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.sm),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceGlassLite,
                            borderRadius:
                                BorderRadius.circular(AppTheme.cardRadiusSm),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(widget.gameTitle, style: AppTheme.headlineMed),
                      const Spacer(),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                Expanded(child: widget.gameBuilder(this)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
