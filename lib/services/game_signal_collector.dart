import 'dart:math' as math;
import 'dart:ui';

import 'package:uuid/uuid.dart';
import 'package:zeno/models/game_session.dart';
import 'package:zeno/models/game_touch_event.dart';
import 'package:zeno/services/game_repository.dart';

/// Raw touch event captured during gameplay.
class GameTouchEvent {
  final int reactionTimeMs;
  final double tapPressure;
  final Offset tapPosition;
  final String eventType; // 'tap_hit', 'tap_miss', 'swipe', 'session_start', 'session_end'
  final DateTime timestamp;
  final Map<String, dynamic> gameContext;

  const GameTouchEvent({
    required this.reactionTimeMs,
    required this.tapPressure,
    required this.tapPosition,
    required this.eventType,
    required this.timestamp,
    this.gameContext = const {},
  });
}

/// Singleton signal collector used by all games.
///
/// Call [markStimulus] when a stimulus appears, [recordTouch] on every
/// interaction, and [flushSession] when the game ends.
class GameSignalCollector {
  GameSignalCollector._();
  static final GameSignalCollector _instance = GameSignalCollector._();
  factory GameSignalCollector() => _instance;

  static const _uuid = Uuid();

  final List<GameTouchEvent> _buffer = [];
  List<GameTouchEventRecord> _lastFlushedEvents = const [];
  DateTime? _lastStimulusTime;
  DateTime? _sessionStart;

  /// Mark the moment a stimulus appears on screen.
  void markStimulus() {
    _lastStimulusTime = DateTime.now();
  }

  /// Record a touch event. [reactionTimeMs] is auto-computed from last
  /// [markStimulus] call if not provided.
  void recordTouch({
    int? reactionTimeMs,
    double tapPressure = 0.5,
    Offset tapPosition = Offset.zero,
    required String eventType,
    Map<String, dynamic> gameContext = const {},
  }) {
    final now = DateTime.now();

    if (eventType == 'session_start') {
      _sessionStart = now;
      _buffer.clear();
    }

    int rt = reactionTimeMs ?? 0;
    if (reactionTimeMs == null && _lastStimulusTime != null) {
      rt = now.difference(_lastStimulusTime!).inMilliseconds;
    }

    _buffer.add(GameTouchEvent(
      reactionTimeMs: rt,
      tapPressure: tapPressure.clamp(0.0, 1.0),
      tapPosition: tapPosition,
      eventType: eventType,
      timestamp: now,
      gameContext: gameContext,
    ));
  }

  /// Aggregate raw buffer into a [GameSession], compute z-score deltas
  /// against the user's 7-day baseline, clear the buffer, and return the
  /// session object.
  Future<GameSession> flushSession({
    required String gameId,
    required int levelReached,
    bool dropOffEarly = false,
    String userId = 'alex',
  }) async {
    final now = DateTime.now();
    final start = _sessionStart ?? now;
    final sessionId = _uuid.v4();

    _buffer.add(GameTouchEvent(
      reactionTimeMs: 0,
      tapPressure: 0,
      tapPosition: Offset.zero,
      eventType: 'session_end',
      timestamp: now,
      gameContext: {'drop_off_early': dropOffEarly},
    ));

    final scoredInteractions = _buffer.where((event) {
      if (event.eventType == 'session_start' || event.eventType == 'session_end') {
        return false;
      }
      return event.gameContext['exclude_from_accuracy'] != true;
    }).toList();
    final hits = scoredInteractions
        .where((event) => event.eventType == 'tap_hit' || event.eventType == 'swipe')
        .toList();
    final misses = scoredInteractions.where((e) => e.eventType == 'tap_miss').toList();
    final total = hits.length + misses.length;

    // Averages
    double avgReaction = 0;
    double avgPressure = 0.5;
    double pressureVar = 0;

    if (scoredInteractions.isNotEmpty) {
      avgReaction = scoredInteractions.fold<double>(0, (s, e) => s + e.reactionTimeMs) /
          scoredInteractions.length;
      avgPressure =
          scoredInteractions.fold<double>(0, (s, e) => s + e.tapPressure) / scoredInteractions.length;
      final mean = avgPressure;
      pressureVar =
          scoredInteractions.fold<double>(
                0,
                (s, e) => s + (e.tapPressure - mean) * (e.tapPressure - mean),
              ) /
              scoredInteractions.length;
    }

    final errorRate = total > 0 ? misses.length / total : 0.0;

    // Hesitation index: % of taps with reactionTime > 1.5x baseline
    double hesitationIndex = 0;
    final repo = GameRepository();
    final baseline = await repo.getBaseline(userId, gameId);
    final baselineRt = baseline?.baselineReactionMs ?? avgReaction;

    if (scoredInteractions.isNotEmpty && baselineRt > 0) {
      final threshold = baselineRt * 1.5;
      final hesitant =
          scoredInteractions.where((event) => event.reactionTimeMs > threshold).length;
      hesitationIndex = hesitant / scoredInteractions.length;
    }

    // Z-score deltas vs baseline
    double reactionDelta = 0;
    double pressureDelta = 0;
    double errorDelta = 0;

    if (baseline != null) {
      // Compute standard deviations from recent sessions
      final recentSessions = await repo.getRecentGameSessions(userId, gameId, days: 7);
      if (recentSessions.length >= 3) {
        reactionDelta = _zScore(
          avgReaction,
          baseline.baselineReactionMs,
          recentSessions.map((session) => session.avgReactionMs).toList(),
        );
        pressureDelta = _zScore(
          avgPressure,
          baseline.baselinePressure,
          recentSessions.map((session) => session.avgPressure).toList(),
        );
        errorDelta = _zScore(
          errorRate,
          baseline.baselineErrorRate,
          recentSessions.map((session) => session.errorRate).toList(),
        );
      }
    }

    final session = GameSession(
      id: sessionId,
      userId: userId,
      gameId: gameId,
      startedAt: start,
      endedAt: now,
      sessionLengthSec: now.difference(start).inSeconds,
      avgReactionMs: avgReaction,
      avgPressure: avgPressure,
      pressureVariance: pressureVar,
      errorRate: errorRate,
      hesitationIndex: hesitationIndex,
      levelReached: levelReached,
      dropOffEarly: dropOffEarly,
      reactionDelta: reactionDelta,
      pressureDelta: pressureDelta,
      errorDelta: errorDelta,
    );

    _lastFlushedEvents = _buffer
        .map(
          (event) => GameTouchEventRecord(
            id: _uuid.v4(),
            sessionId: sessionId,
            userId: userId,
            gameId: gameId,
            reactionTimeMs: event.reactionTimeMs,
            tapPressure: event.tapPressure,
            tapPosition: event.tapPosition,
            eventType: event.eventType,
            timestamp: event.timestamp,
            gameContext: event.gameContext,
          ),
        )
        .toList(growable: false);

    _buffer.clear();
    _lastStimulusTime = null;
    _sessionStart = null;

    return session;
  }

  List<GameTouchEventRecord> takeLastFlushedEvents() {
    final events = _lastFlushedEvents;
    _lastFlushedEvents = const [];
    return events;
  }

  double _zScore(double value, double mean, List<double> samples) {
    if (samples.length < 2) return 0;
    final avg = samples.reduce((a, b) => a + b) / samples.length;
    final variance = samples.fold<double>(0, (s, v) => s + (v - avg) * (v - avg)) / samples.length;
    final sd = variance > 0 ? math.sqrt(variance) : 1.0;
    return (value - mean) / sd;
  }
}
