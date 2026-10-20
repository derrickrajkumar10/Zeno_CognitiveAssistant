import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/models/game_session.dart';
import 'package:zeno/models/game_touch_event.dart';

void main() {
  test('a game session survives a round trip through storage', () {
    final original = GameSession(
      id: 's1',
      userId: 'alex',
      gameId: 'memory_garden',
      startedAt: DateTime(2026, 10, 20, 9),
      endedAt: DateTime(2026, 10, 20, 9, 3),
      sessionLengthSec: 180,
      avgReactionMs: 420.5,
      avgPressure: 0.55,
      pressureVariance: 0.02,
      errorRate: 0.2,
      hesitationIndex: 0.1,
      levelReached: 4,
      dropOffEarly: true,
      reactionDelta: 1.2,
      pressureDelta: -0.3,
      errorDelta: 0.4,
    );

    final map = original.toMap();
    expect(map['drop_off_early'], 1);
    expect(GameSession.fromMap(map).toMap(), map);
  });

  test('sessions saved before deltas existed load with zero deltas', () {
    final map = {
      'id': 's0',
      'user_id': 'alex',
      'game_id': 'wave_sync',
      'started_at': '2026-10-01T09:00:00.000',
      'ended_at': '2026-10-01T09:02:00.000',
      'session_length_sec': 120,
      'avg_reaction_ms': 300,
      'avg_pressure': 0.5,
      'pressure_variance': 0.0,
      'error_rate': 0.0,
      'hesitation_index': 0.0,
      'level_reached': 1,
      'drop_off_early': 0,
    };
    final loaded = GameSession.fromMap(map);
    expect(loaded.dropOffEarly, isFalse);
    expect(loaded.reactionDelta, 0);
    expect(loaded.pressureDelta, 0);
    expect(loaded.errorDelta, 0);
  });

  test('a game baseline survives a round trip through storage', () {
    final baseline = GameBaseline(
      userId: 'alex',
      gameId: 'dream_sort',
      baselineReactionMs: 510,
      baselinePressure: 0.48,
      baselineErrorRate: 0.12,
      updatedAt: DateTime(2026, 10, 20),
    );
    expect(GameBaseline.fromMap(baseline.toMap()).toMap(), baseline.toMap());
  });

  test('a touch event keeps its position and game context', () {
    final event = GameTouchEventRecord(
      id: 'e1',
      sessionId: 's1',
      userId: 'alex',
      gameId: 'focus_flicker',
      reactionTimeMs: 350,
      tapPressure: 0.7,
      tapPosition: const Offset(12.5, 40),
      eventType: 'tap_miss',
      timestamp: DateTime(2026, 10, 20, 9, 1),
      gameContext: const {'rule_flipped': true},
    );

    final copy = GameTouchEventRecord.fromMap(event.toMap());
    expect(copy.tapPosition, const Offset(12.5, 40));
    expect(copy.gameContext, {'rule_flipped': true});
    expect(copy.toMap(), event.toMap());
  });
}
