import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/models/baseline.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/services/cognipulse_engine.dart';

final _now = DateTime(2026, 10, 16, 15);

SignalReading _reading(SignalType type, int score, DateTime at,
        {double? stress, double? mood}) =>
    SignalReading(type: type, score: score, at: at, stress: stress, mood: mood);

void main() {
  group('CogniPulseEngine.today', () {
    test('no check-ins and no baseline gives a neutral 60', () {
      final result = CogniPulseEngine.today(const [], null, _now);
      expect(result.score, 60);
      expect(result.hasCheckInToday, isFalse);
    });

    test('no check-ins uses the baseline score', () {
      final baseline = BaselineResult(answers: const [5, 5, 5, 5, 5], at: _now);
      final result = CogniPulseEngine.today(const [], baseline, _now);
      expect(result.score, 100);
    });

    test('weights are renormalised over the signals measured today', () {
      // mood 90 (w .15) + baseline 60 (w .10) -> (13.5 + 6) / .25 = 78
      final result = CogniPulseEngine.today(
        [_reading(SignalType.selfReport, 90, _now)],
        null,
        _now,
      );
      expect(result.score, 78);
    });

    test('the latest reading of each type wins', () {
      final result = CogniPulseEngine.today(
        [
          _reading(SignalType.selfReport, 10, _now.subtract(const Duration(hours: 2))),
          _reading(SignalType.selfReport, 90, _now.subtract(const Duration(hours: 1))),
        ],
        null,
        _now,
      );
      expect(result.score, 78);
    });

    test('readings from yesterday are ignored', () {
      final result = CogniPulseEngine.today(
        [_reading(SignalType.typing, 10, _now.subtract(const Duration(days: 1)))],
        null,
        _now,
      );
      expect(result.score, 60);
      expect(result.hasCheckInToday, isFalse);
    });

    test('all four measured signals plus baseline use PRD weights', () {
      // typing .35*80 + face .20*50 + mood .15*70 + game .15*40 + base .10*60
      // = 28 + 10 + 10.5 + 6 + 6 = 60.5 / .95 = 63.68 -> 64
      final result = CogniPulseEngine.today(
        [
          _reading(SignalType.typing, 80, _now),
          _reading(SignalType.faceScan, 50, _now),
          _reading(SignalType.selfReport, 70, _now),
          _reading(SignalType.game, 40, _now),
        ],
        null,
        _now,
      );
      expect(result.score, 64);
    });

    test('phone usage is always listed as not measured', () {
      final result = CogniPulseEngine.today(const [], null, _now);
      final phone = result.parts.firstWhere((p) => p.label == 'Phone usage');
      expect(phone.measured, isFalse);
      expect(phone.weight, 0.30);
      expect(phone.share, 0);
    });

    test('shares of measured parts add up to 1', () {
      final result = CogniPulseEngine.today(
        [_reading(SignalType.typing, 80, _now)],
        null,
        _now,
      );
      final total = result.parts.fold<double>(0, (sum, p) => sum + p.share);
      expect(total, closeTo(1, 1e-9));
    });
  });

  group('CogniPulseEngine.lastDays', () {
    test('returns 7 days oldest first ending today, with gaps as null', () {
      final days = CogniPulseEngine.lastDays(
        [_reading(SignalType.selfReport, 90, _now.subtract(const Duration(days: 2)), mood: 90)],
        null,
        _now,
      );
      expect(days.length, 7);
      expect(days.last.day, DateTime(2026, 10, 16));
      expect(days.first.day, DateTime(2026, 10, 10));
      expect(days[4].score, 78);
      expect(days[4].mood, 90);
      expect(days[6].score, isNull);
      expect(days[0].readings, 0);
    });

    test('stress and mood average the readings that carry them', () {
      final days = CogniPulseEngine.lastDays(
        [
          _reading(SignalType.faceScan, 60, _now, stress: 40, mood: 70),
          _reading(SignalType.typing, 80, _now, stress: 20),
        ],
        null,
        _now,
      );
      expect(days.last.stress, 30);
      expect(days.last.mood, 70);
    });
  });
}
