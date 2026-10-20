import 'dart:math';

import 'package:zeno/mock_data.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/models/xp_event.dart';

/// Builds a believable past week of check-ins for demos, so Insights and the
/// weekly letter have something to show on a fresh install. Today is left
/// empty so a live check-in during the demo visibly moves the score.
///
/// Every row is tagged: signals carry a `demo` note and XP rows a `demo_`
/// source id, so the developer panel can replace or remove them.
class DemoSeeder {
  DemoSeeder._();

  static const _gameIds = ['bubble_drift', 'wave_sync', 'memory_garden'];

  /// The week's shape, oldest day first: a dip midweek, then recovery.
  static const _dayLevels = [62, 55, 46, 52, 64, 71];

  /// Mood check-ins can only take the five values the Home picker offers.
  static const _moodValues = [10, 30, 50, 70, 90];

  static bool isDemoSignal(SignalReading s) => s.note?.startsWith('demo') ?? false;

  static bool isDemoXp(XpEvent e) => e.sourceId?.startsWith('demo_') ?? false;

  static ({List<SignalReading> signals, List<XpEvent> xpEvents}) week(
    DateTime now, {
    int seed = 7,
  }) {
    final random = Random(seed);
    final signals = <SignalReading>[];
    final xp = <XpEvent>[];
    int jitter(int range) => random.nextInt(range * 2 + 1) - range;
    int clampScore(num value) => value.round().clamp(0, 100);

    for (var i = 0; i < _dayLevels.length; i++) {
      final daysAgo = _dayLevels.length - i;
      final level = _dayLevels[i];
      DateTime at(int hour, int minute) =>
          DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

      final moodTarget = level + jitter(10);
      final mood = _moodValues.reduce(
          (a, b) => (b - moodTarget).abs() < (a - moodTarget).abs() ? b : a);
      final moodAt = at(8, random.nextInt(50));
      signals.add(SignalReading(
        type: SignalType.selfReport,
        score: mood,
        at: moodAt,
        mood: mood.toDouble(),
        note: 'demo',
      ));
      xp.add(XpEvent(source: SignalType.selfReport.name, sourceId: 'demo_mood', amount: 5, at: moodAt));

      if (random.nextDouble() < 0.7) {
        final typing = clampScore(level - 4 + jitter(8));
        final typingAt = at(20, random.nextInt(50));
        signals.add(SignalReading(
          type: SignalType.typing,
          score: typing,
          at: typingAt,
          stress: (100 - typing).toDouble(),
          note: 'demo',
        ));
        xp.add(XpEvent(source: SignalType.typing.name, sourceId: 'demo_typing', amount: 15, at: typingAt));
      }

      if (random.nextDouble() < 0.5) {
        final gameId = _gameIds[random.nextInt(_gameIds.length)];
        final game = clampScore(level + 6 + jitter(8));
        final gameAt = at(13, random.nextInt(50));
        signals.add(SignalReading(
          type: SignalType.game,
          score: game,
          at: gameAt,
          stress: (100 - game).toDouble(),
          note: 'demo:$gameId',
        ));
        xp.add(XpEvent(source: 'game', sourceId: 'demo_$gameId', amount: 30, at: gameAt));
      }

      final quest = MockData.quests[random.nextInt(MockData.quests.length)];
      xp.add(XpEvent(
        source: 'quest',
        sourceId: 'demo_${quest.id}',
        amount: quest.xpReward,
        at: at(17, random.nextInt(50)),
      ));
    }

    signals.sort((a, b) => a.at.compareTo(b.at));
    return (signals: signals, xpEvents: xp);
  }
}
