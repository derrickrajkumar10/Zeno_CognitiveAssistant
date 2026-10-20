import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/models/xp_event.dart';
import 'package:zeno/services/weekly_letter.dart';

void main() {
  // Friday.
  final now = DateTime(2026, 10, 16, 18);

  SignalReading mood(int score, DateTime at) =>
      SignalReading(type: SignalType.selfReport, score: score, at: at);

  test('with no check-ins the letter says so instead of inventing a week', () {
    final letter = WeeklyLetter.write(
      name: 'Sam',
      signals: const [],
      baseline: null,
      xpEvents: const [],
      now: now,
    );
    expect(letter, startsWith('Dear Sam,'));
    expect(letter, contains("hasn't seen a check-in"));
    expect(letter, isNot(contains('averaged')));
  });

  test('the letter is written from the week\'s real numbers', () {
    final letter = WeeklyLetter.write(
      name: 'Sam',
      signals: [
        mood(40, DateTime(2026, 10, 12, 9)),
        mood(45, DateTime(2026, 10, 13, 9)),
        mood(80, DateTime(2026, 10, 15, 9)),
        mood(85, DateTime(2026, 10, 16, 9)),
      ],
      baseline: null,
      xpEvents: [
        XpEvent(source: 'quest', sourceId: 'walk', amount: 50, at: DateTime(2026, 10, 15, 12)),
        XpEvent(source: 'quest', sourceId: 'breathing', amount: 40, at: DateTime(2026, 10, 16, 12)),
        // Last month: not this week.
        XpEvent(source: 'quest', sourceId: 'walk', amount: 50, at: DateTime(2026, 9, 1, 12)),
      ],
      now: now,
    );

    // Day scores 48, 51, 72, 75 → average 62.
    expect(letter, contains('4 of the last 7 days'));
    expect(letter, contains('averaged 62'));
    expect(letter, contains('Friday, at 75'));
    expect(letter, contains('rose about 24 points'));
    expect(letter, contains('2 quests'));
    expect(letter, contains('Steady'));
  });
}
