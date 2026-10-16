import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/baseline.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/models/xp_event.dart';
import 'package:zeno/services/wellness_repository.dart';

void main() {
  late SharedPreferences prefs;
  late WellnessRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = WellnessRepository(prefs);
  });

  test('signals round-trip through storage', () async {
    final reading = SignalReading(
      type: SignalType.typing,
      score: 72,
      at: DateTime.now(),
      stress: 28,
      note: '41 wpm',
    );
    await repo.saveSignals([reading]);

    final loaded = WellnessRepository(prefs).loadSignals();
    expect(loaded.single.type, SignalType.typing);
    expect(loaded.single.score, 72);
    expect(loaded.single.stress, 28);
    expect(loaded.single.mood, isNull);
    expect(loaded.single.note, '41 wpm');
  });

  test('readings older than 60 days are dropped on save', () async {
    final old = SignalReading(
      type: SignalType.selfReport,
      score: 50,
      at: DateTime.now().subtract(const Duration(days: 61)),
    );
    await repo.saveSignals([old]);
    expect(repo.loadSignals(), isEmpty);
  });

  test('xp events, baseline, counters and name round-trip', () async {
    await repo.saveXpEvents([
      XpEvent(source: 'quest', sourceId: 'walk', amount: 50, at: DateTime(2026, 10, 16)),
    ]);
    await repo.saveBaseline(BaselineResult(answers: const [1, 2, 3, 4, 5], at: DateTime(2026, 10, 16)));
    await repo.saveCounters({'mochi_taps': 3});
    await repo.saveUserName('Sam');

    final fresh = WellnessRepository(prefs);
    expect(fresh.loadXpEvents().single.sourceId, 'walk');
    expect(fresh.loadBaseline()!.answers, [1, 2, 3, 4, 5]);
    expect(fresh.loadCounters()['mochi_taps'], 3);
    expect(fresh.loadUserName(), 'Sam');
  });

  test('corrupt JSON loads as empty instead of crashing', () async {
    await prefs.setString(WellnessRepository.signalsKey, '{not json');
    await prefs.setString(WellnessRepository.xpEventsKey, '[{"amount": "lots"}]');
    await prefs.setString(WellnessRepository.baselineKey, '42');
    await prefs.setString(WellnessRepository.countersKey, '[]');

    expect(repo.loadSignals(), isEmpty);
    expect(repo.loadXpEvents(), isEmpty);
    expect(repo.loadBaseline(), isNull);
    expect(repo.loadCounters(), isEmpty);
  });

  test('an unknown signal type is skipped, the rest still load', () async {
    await prefs.setString(
      WellnessRepository.signalsKey,
      '[{"type":"phone_usage","score":50,"at":"2026-10-16T09:00:00.000"},'
      '{"type":"selfReport","score":70,"at":"2026-10-16T09:00:00.000"}]',
    );
    expect(repo.loadSignals().single.type, SignalType.selfReport);
  });
}
