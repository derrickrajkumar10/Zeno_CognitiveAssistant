/// A single completed game session with aggregated signal data.
class GameSession {
  final String id;
  final String userId;
  final String gameId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int sessionLengthSec;
  final double avgReactionMs;
  final double avgPressure;
  final double pressureVariance;
  final double errorRate;
  final double hesitationIndex;
  final int levelReached;
  final bool dropOffEarly;
  final double reactionDelta;
  final double pressureDelta;
  final double errorDelta;

  const GameSession({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.startedAt,
    required this.endedAt,
    required this.sessionLengthSec,
    required this.avgReactionMs,
    required this.avgPressure,
    required this.pressureVariance,
    required this.errorRate,
    required this.hesitationIndex,
    required this.levelReached,
    required this.dropOffEarly,
    this.reactionDelta = 0.0,
    this.pressureDelta = 0.0,
    this.errorDelta = 0.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'game_id': gameId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'session_length_sec': sessionLengthSec,
        'avg_reaction_ms': avgReactionMs,
        'avg_pressure': avgPressure,
        'pressure_variance': pressureVariance,
        'error_rate': errorRate,
        'hesitation_index': hesitationIndex,
        'level_reached': levelReached,
        'drop_off_early': dropOffEarly ? 1 : 0,
        'reaction_delta': reactionDelta,
        'pressure_delta': pressureDelta,
        'error_delta': errorDelta,
      };

  factory GameSession.fromMap(Map<String, dynamic> map) => GameSession(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        gameId: map['game_id'] as String,
        startedAt: DateTime.parse(map['started_at'] as String),
        endedAt: DateTime.parse(map['ended_at'] as String),
        sessionLengthSec: map['session_length_sec'] as int,
        avgReactionMs: (map['avg_reaction_ms'] as num).toDouble(),
        avgPressure: (map['avg_pressure'] as num).toDouble(),
        pressureVariance: (map['pressure_variance'] as num).toDouble(),
        errorRate: (map['error_rate'] as num).toDouble(),
        hesitationIndex: (map['hesitation_index'] as num).toDouble(),
        levelReached: map['level_reached'] as int,
        dropOffEarly: (map['drop_off_early'] as int) == 1,
        reactionDelta: (map['reaction_delta'] as num?)?.toDouble() ?? 0.0,
        pressureDelta: (map['pressure_delta'] as num?)?.toDouble() ?? 0.0,
        errorDelta: (map['error_delta'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Rolling 7-day baseline for a specific game.
class GameBaseline {
  final String userId;
  final String gameId;
  final double baselineReactionMs;
  final double baselinePressure;
  final double baselineErrorRate;
  final DateTime updatedAt;

  const GameBaseline({
    required this.userId,
    required this.gameId,
    required this.baselineReactionMs,
    required this.baselinePressure,
    required this.baselineErrorRate,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'game_id': gameId,
        'baseline_reaction_ms': baselineReactionMs,
        'baseline_pressure': baselinePressure,
        'baseline_error_rate': baselineErrorRate,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory GameBaseline.fromMap(Map<String, dynamic> map) => GameBaseline(
        userId: map['user_id'] as String,
        gameId: map['game_id'] as String,
        baselineReactionMs: (map['baseline_reaction_ms'] as num).toDouble(),
        baselinePressure: (map['baseline_pressure'] as num).toDouble(),
        baselineErrorRate: (map['baseline_error_rate'] as num).toDouble(),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
