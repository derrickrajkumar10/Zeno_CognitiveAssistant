import 'package:zeno/models/baseline.dart';
import 'package:zeno/models/signal_reading.dart';

/// One row of the "Why is my score X?" breakdown.
class SignalContribution {
  final String label;

  /// The 0–100 reading used, or null when the signal was not measured.
  final int? value;

  /// The signal's nominal weight (PRD weight, or the extras below).
  final double weight;

  /// The weight's share of the weights actually used; 0 when unmeasured.
  final double share;
  final DateTime? at;
  final bool measured;

  const SignalContribution({
    required this.label,
    required this.value,
    required this.weight,
    required this.share,
    required this.at,
    required this.measured,
  });

  /// How many points of the final score this signal supplied.
  double get points => (value ?? 0) * share;
}

class CogniPulseBreakdown {
  final int score;
  final List<SignalContribution> parts;
  final bool hasCheckInToday;
  final bool hasBaseline;

  const CogniPulseBreakdown({
    required this.score,
    required this.parts,
    required this.hasCheckInToday,
    required this.hasBaseline,
  });
}

class DaySummary {
  final DateTime day;
  final int? score;
  final double? stress;
  final double? mood;
  final int readings;

  const DaySummary({
    required this.day,
    required this.score,
    required this.stress,
    required this.mood,
    required this.readings,
  });

  bool get hasData => score != null;
}

/// Fuses the latest reading of each signal from one calendar day into the
/// CogniPulse score: a weighted mean over the signals that were measured.
class CogniPulseEngine {
  CogniPulseEngine._();

  /// PRD §5.2 weights. Game play is an addition the PRD does not list.
  static const Map<SignalType, double> weights = {
    SignalType.typing: 0.35,
    SignalType.faceScan: 0.20,
    SignalType.selfReport: 0.15,
    SignalType.game: 0.15,
  };

  /// PRD weight of phone usage, which this build does not measure.
  static const double phoneUsageWeight = 0.30;

  /// The onboarding questionnaire is always included as a light prior.
  static const double baselineWeight = 0.10;

  /// Used in place of the questionnaire when onboarding was skipped.
  static const int neutralBaseline = 60;

  static CogniPulseBreakdown today(
    List<SignalReading> readings,
    BaselineResult? baseline,
    DateTime now,
  ) {
    return _fuse(_latestPerType(_onDay(readings, now)), baseline);
  }

  static List<DaySummary> lastDays(
    List<SignalReading> readings,
    BaselineResult? baseline,
    DateTime now, {
    int days = 7,
  }) {
    final today = _dateOnly(now);
    return List.generate(days, (index) {
      // Calendar arithmetic, not Duration, so DST changes never skip a day.
      final day = DateTime(today.year, today.month, today.day - (days - 1 - index));
      final dayReadings = _onDay(readings, day);
      if (dayReadings.isEmpty) {
        return DaySummary(day: day, score: null, stress: null, mood: null, readings: 0);
      }
      final latest = _latestPerType(dayReadings);
      return DaySummary(
        day: day,
        score: _fuse(latest, baseline).score,
        stress: _mean(latest.values.map((r) => r.stress)),
        mood: _mean(latest.values.map((r) => r.mood)),
        readings: dayReadings.length,
      );
    });
  }

  static CogniPulseBreakdown _fuse(
    Map<SignalType, SignalReading> latest,
    BaselineResult? baseline,
  ) {
    final baselineValue = baseline?.score ?? neutralBaseline;
    final usedWeight = latest.keys.fold<double>(
          0,
          (sum, type) => sum + weights[type]!,
        ) +
        baselineWeight;
    final weighted = latest.entries.fold<double>(
          0,
          (sum, entry) => sum + entry.value.score * weights[entry.key]!,
        ) +
        baselineValue * baselineWeight;

    SignalContribution part(SignalType type) {
      final reading = latest[type];
      return SignalContribution(
        label: type.label,
        value: reading?.score,
        weight: weights[type]!,
        share: reading == null ? 0 : weights[type]! / usedWeight,
        at: reading?.at,
        measured: reading != null,
      );
    }

    return CogniPulseBreakdown(
      score: (weighted / usedWeight).round().clamp(0, 100),
      hasCheckInToday: latest.isNotEmpty,
      hasBaseline: baseline != null,
      parts: [
        part(SignalType.typing),
        const SignalContribution(
          label: 'Phone usage',
          value: null,
          weight: phoneUsageWeight,
          share: 0,
          at: null,
          measured: false,
        ),
        part(SignalType.faceScan),
        part(SignalType.selfReport),
        part(SignalType.game),
        SignalContribution(
          label: baseline == null ? 'Neutral start' : 'Baseline questionnaire',
          value: baselineValue,
          weight: baselineWeight,
          share: baselineWeight / usedWeight,
          at: baseline?.at,
          measured: true,
        ),
      ],
    );
  }

  static List<SignalReading> _onDay(List<SignalReading> readings, DateTime day) {
    final date = _dateOnly(day);
    return readings.where((r) => _dateOnly(r.at) == date).toList(growable: false);
  }

  static Map<SignalType, SignalReading> _latestPerType(List<SignalReading> readings) {
    final latest = <SignalType, SignalReading>{};
    for (final reading in readings) {
      final current = latest[reading.type];
      // On a timestamp tie the reading added later wins.
      if (current == null || !reading.at.isBefore(current.at)) {
        latest[reading.type] = reading;
      }
    }
    return latest;
  }

  static double? _mean(Iterable<double?> values) {
    final present = values.whereType<double>().toList(growable: false);
    if (present.isEmpty) {
      return null;
    }
    return present.reduce((a, b) => a + b) / present.length;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
