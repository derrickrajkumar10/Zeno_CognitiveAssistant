import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/models/game_touch_event.dart';
import 'package:zeno/services/game_repository.dart';

import 'game_test_helpers.dart';

GameTouchEventRecord _event(String id, String sessionId, DateTime at) {
  return GameTouchEventRecord(
    id: id,
    sessionId: sessionId,
    userId: 'alex',
    gameId: 'bubble_drift',
    reactionTimeMs: 300,
    tapPressure: 0.5,
    tapPosition: const Offset(10, 20),
    eventType: 'tap_hit',
    timestamp: at,
  );
}

void main() {
  final repo = GameRepository();
  final now = DateTime.now();

  setUp(resetGameStore);

  test('recent sessions come back newest first', () async {
    await repo.saveSession(session(id: 'a', startedAt: now.subtract(const Duration(days: 2))));
    await repo.saveSession(session(id: 'b', startedAt: now.subtract(const Duration(hours: 1))));
    await repo.saveSession(session(id: 'c', startedAt: now.subtract(const Duration(days: 1))));

    final sessions = await repo.getRecentSessions('alex');
    expect(sessions.map((s) => s.id), ['b', 'c', 'a']);
  });

  test('sessions older than the window are left out', () async {
    await repo.saveSession(session(id: 'old', startedAt: now.subtract(const Duration(days: 10))));
    await repo.saveSession(session(id: 'new', startedAt: now.subtract(const Duration(days: 1))));

    expect((await repo.getRecentSessions('alex')).map((s) => s.id), ['new']);
    expect((await repo.getRecentSessions('alex', days: 30)).length, 2);
  });

  test('saving the same session twice keeps one copy', () async {
    final first = session(id: 'same', startedAt: now, errorRate: 0.1);
    await repo.saveSession(first);
    await repo.saveSession(session(id: 'same', startedAt: now, errorRate: 0.4));

    final sessions = await repo.getRecentSessions('alex');
    expect(sessions.single.errorRate, 0.4);
  });

  test('the baseline is the mean of the last week of one game', () async {
    await repo.saveSession(session(id: '1', startedAt: now, avgReactionMs: 300, errorRate: 0.1));
    await repo.saveSession(session(id: '2', startedAt: now, avgReactionMs: 500, errorRate: 0.3));
    await repo.saveSession(
      session(id: 'other', gameId: 'wave_sync', startedAt: now, avgReactionMs: 2000),
    );
    await repo.updateBaseline('alex', 'bubble_drift');

    final baseline = await repo.getBaseline('alex', 'bubble_drift');
    expect(baseline!.baselineReactionMs, 400);
    expect(baseline.baselineErrorRate, closeTo(0.2, 1e-9));
    expect(await repo.getBaseline('alex', 'wave_sync'), isNull);
  });

  test('touch events can be fetched for chosen sessions only', () async {
    await repo.saveTouchEvents([
      _event('e1', 's1', now),
      _event('e2', 's2', now.add(const Duration(seconds: 1))),
      _event('e3', 's1', now.add(const Duration(seconds: 2))),
    ]);
    final events = await repo.getTouchEventsForSessionIds(['s1']);
    expect(events.map((e) => e.id), ['e1', 'e3']);
    expect(await repo.getTouchEventsForSessionIds([]), isEmpty);
  });

  test('last played time is the latest end time for that game', () async {
    expect(await repo.getLastPlayedAt('alex', 'bubble_drift'), isNull);
    final started = now.subtract(const Duration(hours: 3));
    await repo.saveSession(session(id: 'x', startedAt: started));
    expect(
      await repo.getLastPlayedAt('alex', 'bubble_drift'),
      started.add(const Duration(minutes: 2)),
    );
  });

  test('clearAll removes sessions, baselines and touch events', () async {
    await repo.saveSession(session(id: 'x', startedAt: now));
    await repo.updateBaseline('alex', 'bubble_drift');
    await repo.saveTouchEvents([_event('e1', 'x', now)]);

    await repo.clearAll();

    expect(await repo.getRecentSessions('alex'), isEmpty);
    expect(await repo.getBaseline('alex', 'bubble_drift'), isNull);
    expect(await repo.getTouchEventsForSessionIds(['x']), isEmpty);
  });
}
