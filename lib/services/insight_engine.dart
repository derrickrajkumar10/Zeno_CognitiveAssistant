import 'package:zeno/models/baseline.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/services/cognipulse_engine.dart';

enum InsightKind { trend, bestDay, typingVsMood, timeOfDay, consistency }

/// One rule-based observation about the last seven days of check-ins.
class Insight {
  final InsightKind kind;
  final String title;
  final String description;

  const Insight({
    required this.kind,
    required this.title,
    required this.description,
  });
}

/// Turns stored check-ins into plain-language patterns. Every rule has a
/// minimum amount of data and a threshold, so a pattern only appears when
/// the readings actually show it.
class InsightEngine {
  InsightEngine._();

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Days with data needed before the week's shape means anything.
  static const minDaysForTrend = 3;

  /// Points of change that count as a trend rather than noise.
  static const trendThreshold = 5;

  /// Check-ins needed both before noon and after 5 pm.
  static const minPerTimeOfDay = 2;
  static const timeOfDayThreshold = 8;

  /// Points between same-day typing and mood scores worth pointing out.
  static const typingMoodGap = 25;

  static String weekdayName(DateTime day) => _weekdays[day.weekday - 1];

  static List<Insight> build(
    List<SignalReading> signals,
    BaselineResult? baseline,
    DateTime now,
  ) {
    final week = CogniPulseEngine.lastDays(signals, baseline, now);
    final firstDay = week.first.day;
    final recent = signals
        .where((s) => !s.at.isBefore(firstDay) && !s.at.isAfter(now))
        .toList(growable: false);
    final withData = week.where((d) => d.hasData).toList(growable: false);
    if (withData.isEmpty) {
      return const [];
    }

    final typingVsMood = _typingVsMood(recent);
    final timeOfDay = _timeOfDay(recent);
    return [
      if (withData.length >= minDaysForTrend) ...[
        _trend(withData),
        _bestDay(withData),
      ],
      if (typingVsMood != null) typingVsMood,
      if (timeOfDay != null) timeOfDay,
      _consistency(withData.length, week.length),
    ];
  }

  static Insight _trend(List<DaySummary> days) {
    final half = days.length ~/ 2;
    final early = _meanScore(days.take(half));
    final late = _meanScore(days.skip(half));
    final change = (late - early).round();
    if (change >= trendThreshold) {
      return Insight(
        kind: InsightKind.trend,
        title: 'Trending up',
        description: 'Your score rose about $change points across the week.',
      );
    }
    if (change <= -trendThreshold) {
      return Insight(
        kind: InsightKind.trend,
        title: 'Trending down',
        description: 'Your score fell about ${-change} points across the week. '
            'A breathing quest or an early night might help.',
      );
    }
    return const Insight(
      kind: InsightKind.trend,
      title: 'Holding steady',
      description: 'Your score stayed within $trendThreshold points across the week.',
    );
  }

  static Insight _bestDay(List<DaySummary> days) {
    final best = days.reduce((a, b) => b.score! > a.score! ? b : a);
    final name = weekdayName(best.day);
    return Insight(
      kind: InsightKind.bestDay,
      title: 'Best day: $name',
      description: 'You scored ${best.score} on $name, your highest this week.',
    );
  }

  static Insight? _typingVsMood(List<SignalReading> recent) {
    // The most recent day that has both a typing and a mood check-in.
    final byDay = <DateTime, Map<SignalType, SignalReading>>{};
    for (final reading in recent) {
      if (reading.type != SignalType.typing && reading.type != SignalType.selfReport) {
        continue;
      }
      final day = DateTime(reading.at.year, reading.at.month, reading.at.day);
      final latest = byDay.putIfAbsent(day, () => {});
      final current = latest[reading.type];
      if (current == null || !reading.at.isBefore(current.at)) {
        latest[reading.type] = reading;
      }
    }
    final days = byDay.keys.where((d) => byDay[d]!.length == 2).toList()..sort();
    if (days.isEmpty) {
      return null;
    }
    final day = days.last;
    final typed = byDay[day]![SignalType.typing]!.score;
    final felt = byDay[day]![SignalType.selfReport]!.score;
    if ((typed - felt).abs() < typingMoodGap) {
      return null;
    }
    final name = weekdayName(day);
    if (typed < felt) {
      return Insight(
        kind: InsightKind.typingVsMood,
        title: 'Your typing looks more tense than you feel',
        description: 'On $name you rated your mood $felt, but your typing check-in '
            'scored $typed. Stress can show in your hands before you notice it.',
      );
    }
    return Insight(
      kind: InsightKind.typingVsMood,
      title: 'You feel lower than your typing suggests',
      description: 'On $name your typing check-in scored $typed, but you rated '
          'your mood $felt. Worth a gentle look at what is weighing on you.',
    );
  }

  static Insight? _timeOfDay(List<SignalReading> recent) {
    final checkIns = recent.where((s) => s.type != SignalType.game);
    final morning = checkIns.where((s) => s.at.hour < 12).toList();
    final evening = checkIns.where((s) => s.at.hour >= 17).toList();
    if (morning.length < minPerTimeOfDay || evening.length < minPerTimeOfDay) {
      return null;
    }
    final am = _mean(morning.map((s) => s.score)).round();
    final pm = _mean(evening.map((s) => s.score)).round();
    if ((am - pm).abs() < timeOfDayThreshold) {
      return null;
    }
    return Insight(
      kind: InsightKind.timeOfDay,
      title: am > pm ? 'Mornings feel lighter' : 'Evenings feel lighter',
      description: 'Your check-ins average $am before noon and $pm after 5 pm.',
    );
  }

  static Insight _consistency(int daysWithData, int totalDays) {
    return Insight(
      kind: InsightKind.consistency,
      title: 'Checked in $daysWithData of the last $totalDays days',
      description: daysWithData >= 5
          ? 'Regular check-ins make your score more trustworthy. Nice rhythm.'
          : 'A few more check-ins will give Mochi a clearer picture.',
    );
  }

  static double _meanScore(Iterable<DaySummary> days) =>
      _mean(days.map((d) => d.score!));

  static double _mean(Iterable<int> values) =>
      values.reduce((a, b) => a + b) / values.length;
}
