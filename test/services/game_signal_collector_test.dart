import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/services/game_repository.dart';
import 'package:zeno/services/game_signal_collector.dart';

import 'game_test_helpers.dart';

void main() {
  final collector = GameSignalCollector();

  setUp(() async {
    await resetGameStore();
    collector.recordTouch(eventType: 'session_start');
  });

  test('error rate, reaction time and pressure come from the taps', () async {
    collector.recordTouch(eventType: 'tap_hit', reactionTimeMs: 300, tapPressure: 0.4);
    collector.recordTouch(eventType: 'tap_hit', reactionTimeMs: 400, tapPressure: 0.6);
    collector.recordTouch(eventType: 'tap_hit', reactionTimeMs: 500, tapPressure: 0.5);
    collector.recordTouch(eventType: 'tap_miss', reactionTimeMs: 600, tapPressure: 0.5);

    final result = await collector.flushSession(gameId: 'bubble_drift', levelReached: 3);

    expect(result.errorRate, 0.25);
    expect(result.avgReactionMs, 450);
    expect(result.avgPressure, closeTo(0.5, 1e-9));
    expect(result.pressureVariance, closeTo(0.005, 1e-9));
    expect(result.levelReached, 3);
    expect(result.dropOffEarly, isFalse);
  });

  test('taps slower than 1.5x the usual reaction count as hesitation', () async {
    for (final ms in [100, 100, 100, 1000]) {
      collector.recordTouch(eventType: 'tap_hit', reactionTimeMs: ms);
    }
    final result = await collector.flushSession(gameId: 'bubble_drift', levelReached: 1);

    // Mean 325 ms, so only the 1000 ms tap passes the 487.5 ms threshold.
    expect(result.hesitationIndex, 0.25);
  });

  test('events marked exclude_from_accuracy do not count as misses', () async {
    collector.recordTouch(eventType: 'tap_hit', reactionTimeMs: 300);
    collector.recordTouch(
      eventType: 'tap_miss',
      reactionTimeMs: 300,
      gameContext: {'exclude_from_accuracy': true},
    );
    final result = await collector.flushSession(gameId: 'wave_sync', levelReached: 1);
    expect(result.errorRate, 0);
  });

  test('a game ended before any tap gives neutral numbers', () async {
    final result = await collector.flushSession(
      gameId: 'bubble_drift',
      levelReached: 0,
      dropOffEarly: true,
    );
    expect(result.errorRate, 0);
    expect(result.hesitationIndex, 0);
    expect(result.avgReactionMs, 0);
    expect(result.avgPressure, 0.5);
    expect(result.dropOffEarly, isTrue);
  });

  test('raw events are handed over once, with pressure clamped to 0–1', () async {
    collector.recordTouch(eventType: 'tap_hit', reactionTimeMs: 200, tapPressure: 3);
    final result = await collector.flushSession(gameId: 'bubble_drift', levelReached: 1);

    final events = collector.takeLastFlushedEvents();
    expect(events.map((e) => e.eventType), ['session_start', 'tap_hit', 'session_end']);
    expect(events.every((e) => e.sessionId == result.id), isTrue);
    expect(events[1].tapPressure, 1.0);
    expect(collector.takeLastFlushedEvents(), isEmpty);
  });

  test('with a baseline and 3+ recent sessions, slow play shows a positive '
      'reaction delta', () async {
    final repo = GameRepository();
    final now = DateTime.now();
    for (final (i, ms) in [400.0, 500.0, 600.0].indexed) {
      await repo.saveSession(session(
        id: 'past-$i',
        startedAt: now.subtract(Duration(hours: i + 1)),
        avgReactionMs: ms,
      ));
    }
    await repo.updateBaseline('alex', 'bubble_drift');

    collector.recordTouch(eventType: 'tap_hit', reactionTimeMs: 800);
    final result = await collector.flushSession(gameId: 'bubble_drift', levelReached: 1);

    // Baseline 500 ms, population SD of [400, 500, 600] = sqrt(20000 / 3).
    expect(result.reactionDelta, closeTo(300 / math.sqrt(20000 / 3), 1e-6));
  });
}
