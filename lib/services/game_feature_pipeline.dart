import 'dart:math' as math;

import 'package:zeno/models/game_session.dart';
import 'package:zeno/models/game_touch_event.dart';
import 'package:zeno/services/game_repository.dart';

/// Normalized feature vector from recent game behavior for CogniPulse scoring.
class GameFeatureVector {
  final double reactionMsZScore;
  final double tapPressureZScore;
  final double pressureVarianceZScore;
  final double errorRateZScore;
  final double hesitationIndexZScore;
  final double sessionCompletionRate;
  final double fatigueCurveDropIndex;
  final double memoryScoreZScore;
  final double flexibilityRecoveryMs;
  final double ruminationEventCount;

  const GameFeatureVector({
    this.reactionMsZScore = 0,
    this.tapPressureZScore = 0,
    this.pressureVarianceZScore = 0,
    this.errorRateZScore = 0,
    this.hesitationIndexZScore = 0,
    // No sessions means no evidence of quitting early.
    this.sessionCompletionRate = 1,
    this.fatigueCurveDropIndex = 0,
    this.memoryScoreZScore = 0,
    this.flexibilityRecoveryMs = 0,
    this.ruminationEventCount = 0,
  });

  /// How strained recent play looks; positive means more strain than usual.
  ///
  /// Every term is oriented so that a higher value means worse play: slower
  /// reactions, more errors and more hesitation add load, while better memory
  /// accuracy and late-game accuracy (fatigue index > 0) subtract it.
  double get stressLoad {
    return reactionMsZScore * 0.20 +
        pressureVarianceZScore * 0.15 +
        errorRateZScore * 0.15 -
        memoryScoreZScore * 0.12 +
        hesitationIndexZScore * 0.12 +
        (1 - sessionCompletionRate) * 0.10 -
        fatigueCurveDropIndex * 0.08 +
        flexibilityRecoveryMs * 0.05 +
        ruminationEventCount * 0.03;
  }

  Map<String, double> toMap() => {
        'reaction_ms_z': reactionMsZScore,
        'tap_pressure_z': tapPressureZScore,
        'pressure_variance_z': pressureVarianceZScore,
        'error_rate_z': errorRateZScore,
        'hesitation_index_z': hesitationIndexZScore,
        'session_completion_rate': sessionCompletionRate,
        'fatigue_curve_drop': fatigueCurveDropIndex,
        'memory_score_z': memoryScoreZScore,
        'flexibility_recovery_ms': flexibilityRecoveryMs,
        'rumination_event_count': ruminationEventCount,
      };
}

class GameFeaturePipeline {
  final GameRepository _repo;

  GameFeaturePipeline({GameRepository? repo}) : _repo = repo ?? GameRepository();

  Future<GameFeatureVector> compute(String userId) async {
    final sessions = await _repo.getRecentSessions(userId, days: 7);
    if (sessions.isEmpty) {
      return const GameFeatureVector();
    }

    final latestSession = sessions.first;
    final touchEvents = await _repo.getTouchEventsForSessionIds(
      sessions.map((session) => session.id).toList(),
    );
    final eventsBySession = _groupEventsBySession(touchEvents);

    final fatigueSamples = <double>[];
    final recoverySamples = <double>[];
    int ruminationCount = 0;

    for (final session in sessions) {
      final sessionEvents = eventsBySession[session.id] ?? const <GameTouchEventRecord>[];
      final fatigue = _fatigueDropIndex(sessionEvents);
      if (fatigue != null) {
        fatigueSamples.add(fatigue);
      }

      final recovery = _flexibilityRecoveryMs(session, sessionEvents);
      if (recovery != null) {
        recoverySamples.add(recovery);
      }

      if (_isRuminationEvent(session, sessionEvents)) {
        ruminationCount++;
      }
    }

    final memorySessions = sessions
        .where((session) => session.gameId == 'memory_garden')
        .toList(growable: false);
    final memoryScores = memorySessions
        .map((session) => 1 - session.errorRate)
        .toList(growable: false);

    final latestEvents =
        eventsBySession[latestSession.id] ?? const <GameTouchEventRecord>[];
    final latestFatigue = _fatigueDropIndex(latestEvents);
    final latestRecovery = _flexibilityRecoveryMs(latestSession, latestEvents);

    return GameFeatureVector(
      reactionMsZScore:
          _zScore(latestSession.avgReactionMs, sessions.map((s) => s.avgReactionMs).toList()),
      tapPressureZScore:
          _zScore(latestSession.avgPressure, sessions.map((s) => s.avgPressure).toList()),
      pressureVarianceZScore: _zScore(
        latestSession.pressureVariance,
        sessions.map((s) => s.pressureVariance).toList(),
      ),
      errorRateZScore:
          _zScore(latestSession.errorRate, sessions.map((s) => s.errorRate).toList()),
      hesitationIndexZScore: _zScore(
        latestSession.hesitationIndex,
        sessions.map((s) => s.hesitationIndex).toList(),
      ),
      sessionCompletionRate:
          sessions.where((session) => !session.dropOffEarly).length / sessions.length,
      fatigueCurveDropIndex: latestFatigue == null ? 0 : _zScore(latestFatigue, fatigueSamples),
      memoryScoreZScore: memorySessions.isEmpty
          ? 0
          : _zScore(1 - memorySessions.first.errorRate, memoryScores),
      flexibilityRecoveryMs:
          latestRecovery == null ? 0 : _zScore(latestRecovery, recoverySamples),
      ruminationEventCount: ruminationCount.toDouble(),
    );
  }

  Map<String, List<GameTouchEventRecord>> _groupEventsBySession(
    List<GameTouchEventRecord> events,
  ) {
    final grouped = <String, List<GameTouchEventRecord>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.sessionId, () => <GameTouchEventRecord>[]).add(event);
    }
    return grouped;
  }

  List<GameTouchEventRecord> _scoredEvents(List<GameTouchEventRecord> events) {
    return events.where((event) {
      if (event.eventType == 'session_start' || event.eventType == 'session_end') {
        return false;
      }
      return event.gameContext['exclude_from_accuracy'] != true;
    }).toList(growable: false);
  }

  bool _isSuccess(GameTouchEventRecord event) {
    return event.eventType == 'tap_hit' || event.eventType == 'swipe';
  }

  double? _fatigueDropIndex(List<GameTouchEventRecord> events) {
    final scored = _scoredEvents(events);
    if (scored.length < 4) {
      return null;
    }
    final quartileSize = math.max(1, scored.length ~/ 4);
    final firstQuartile = scored.take(quartileSize).toList(growable: false);
    final lastQuartile = scored.skip(scored.length - quartileSize).toList(growable: false);
    final firstAccuracy = _accuracy(firstQuartile);
    final lastAccuracy = _accuracy(lastQuartile);
    return lastAccuracy - firstAccuracy;
  }

  double _accuracy(List<GameTouchEventRecord> events) {
    if (events.isEmpty) {
      return 0;
    }
    final correct = events.where(_isSuccess).length;
    return correct / events.length;
  }

  double? _flexibilityRecoveryMs(
    GameSession session,
    List<GameTouchEventRecord> events,
  ) {
    if (session.gameId != 'focus_flicker' && session.gameId != 'dream_sort') {
      return null;
    }
    final scored = _scoredEvents(events);
    if (scored.isEmpty) {
      return null;
    }

    final flipIndex = scored.indexWhere((event) {
      return event.gameContext['rule_flipped'] == true ||
          event.gameContext['inverted'] == true;
    });
    if (flipIndex == -1) {
      return null;
    }

    final flipTime = scored[flipIndex].timestamp;
    final recoveryEvent = scored.skip(flipIndex).firstWhere(
          _isSuccess,
          orElse: () => scored.last,
        );
    return recoveryEvent.timestamp.difference(flipTime).inMilliseconds.toDouble();
  }

  bool _isRuminationEvent(
    GameSession session,
    List<GameTouchEventRecord> events,
  ) {
    if (session.hesitationIndex < 0.45) {
      return false;
    }
    final scored = _scoredEvents(events);
    if (scored.isEmpty) {
      return false;
    }
    return _isSuccess(scored.last);
  }

  double _zScore(double value, List<double> samples) {
    if (samples.length < 2) {
      return 0;
    }
    final mean = samples.reduce((a, b) => a + b) / samples.length;
    final variance = samples.fold<double>(
          0,
          (sum, sample) => sum + math.pow(sample - mean, 2).toDouble(),
        ) /
        samples.length;
    final standardDeviation = math.sqrt(variance);
    if (standardDeviation == 0) {
      return 0;
    }
    return (value - mean) / standardDeviation;
  }
}

class CogniPulseGameContributor {
  final GameFeaturePipeline _pipeline;

  CogniPulseGameContributor({GameFeaturePipeline? pipeline})
      : _pipeline = pipeline ?? GameFeaturePipeline();

  Future<int> computeAdjustment(String userId) async {
    final features = await _pipeline.compute(userId);
    final clamped = features.stressLoad.clamp(-3.0, 3.0);
    // More strain lowers CogniPulse; calmer, sharper play raises it.
    return -(clamped * 5).round();
  }

  /// The game-play signal for CogniPulse, 30–90.
  ///
  /// Play that matches your own recent baseline reads as a neutral 60; each
  /// point of adjustment moves it by 2.
  Future<int> computeSignalScore(String userId) async {
    final adjustment = await computeAdjustment(userId);
    return (60 + adjustment * 2).clamp(30, 90);
  }
}
