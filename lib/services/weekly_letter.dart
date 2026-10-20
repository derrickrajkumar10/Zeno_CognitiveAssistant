import 'package:zeno/models/baseline.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/models/xp_event.dart';
import 'package:zeno/services/cognipulse_engine.dart';
import 'package:zeno/services/insight_engine.dart';

/// Mochi's weekly letter, written from the last seven days of stored
/// check-ins and quests. Every number in it comes from the user's data.
class WeeklyLetter {
  WeeklyLetter._();

  static String write({
    required String name,
    required List<SignalReading> signals,
    required BaselineResult? baseline,
    required List<XpEvent> xpEvents,
    required DateTime now,
  }) {
    final week = CogniPulseEngine.lastDays(signals, baseline, now);
    final withData = week.where((d) => d.hasData).toList(growable: false);
    const signOff = '\n\nMochi will be here.\n— Mochi 🐻';

    if (withData.isEmpty) {
      return 'Dear $name,\n\n'
          "Mochi hasn't seen a check-in from you this week yet. That's okay. "
          'When you are ready, log your mood on Home or try a typing check-in '
          'in Scan, and next week this letter will be about you.'
          '$signOff';
    }

    final average =
        (withData.map((d) => d.score!).reduce((a, b) => a + b) / withData.length)
            .round();
    final firstDay = week.first.day;
    final quests = xpEvents
        .where((e) => e.source == 'quest' && !e.at.isBefore(firstDay) && !e.at.isAfter(now))
        .length;
    final trend = InsightEngine.build(signals, baseline, now)
        .where((i) => i.kind == InsightKind.trend)
        .firstOrNull;

    final lines = <String>[
      'You checked in on ${withData.length} of the last ${week.length} days, '
          'and your CogniPulse averaged $average.',
    ];
    if (withData.length >= 2) {
      final best = withData.reduce((a, b) => b.score! > a.score! ? b : a);
      lines.add('Your brightest day was ${InsightEngine.weekdayName(best.day)}, '
          'at ${best.score}.');
    }
    if (trend != null) {
      lines.add(trend.description);
    }
    if (quests > 0) {
      lines.add('You finished $quests ${quests == 1 ? 'quest' : 'quests'} along the way.');
    }

    final String closing;
    if (average >= 75) {
      closing = 'Whatever you are doing, keep doing it. Mochi is proud of you.';
    } else if (average >= 55) {
      closing = 'Steady is underrated. Mochi values that more than peaks.';
    } else {
      closing = 'It was a heavier week. You still showed up, and that counts '
          'for more than any number.';
    }

    return 'Dear $name,\n\n${lines.join(' ')}\n\n$closing$signOff';
  }
}
