import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/services/progress_engine.dart';

DateTime _d(int day) => DateTime(2026, 10, day);

void main() {
  group('levels', () {
    test('every 250 XP is one level, starting at level 1', () {
      expect(ProgressEngine.level(0), 1);
      expect(ProgressEngine.level(249), 1);
      expect(ProgressEngine.level(250), 2);
      expect(ProgressEngine.level(1240), 5);
      expect(ProgressEngine.xpIntoLevel(1240), 240);
    });
  });

  group('streaks', () {
    test('no activity is a 0-day streak', () {
      expect(ProgressEngine.currentStreak({}, _d(16)), 0);
    });

    test('consecutive days ending today count', () {
      expect(ProgressEngine.currentStreak({_d(14), _d(15), _d(16)}, _d(16)), 3);
    });

    test('a streak ending yesterday is still alive today', () {
      expect(ProgressEngine.currentStreak({_d(14), _d(15)}, _d(16)), 2);
    });

    test('a gap resets the streak', () {
      expect(ProgressEngine.currentStreak({_d(12), _d(13), _d(16)}, _d(16)), 1);
      expect(ProgressEngine.currentStreak({_d(12), _d(13)}, _d(16)), 0);
    });

    test('longest streak finds the best run anywhere', () {
      expect(
        ProgressEngine.longestStreak({_d(1), _d(2), _d(3), _d(4), _d(9), _d(10)}),
        4,
      );
    });

    test('streaks survive the month boundary', () {
      expect(
        ProgressEngine.currentStreak(
            {DateTime(2026, 9, 30), DateTime(2026, 10, 1)}, DateTime(2026, 10, 1)),
        2,
      );
    });
  });

  group('badges', () {
    test('nothing done means every badge is locked', () {
      final badges = ProgressEngine.badges(const BadgeStats());
      expect(badges, isNotEmpty);
      expect(badges.where((b) => b.unlocked), isEmpty);
    });

    test('badges unlock from real stats and report progress', () {
      final badges = ProgressEngine.badges(const BadgeStats(
        checkIns: 1,
        longestStreak: 5,
        mochiTaps: 12,
        breathingSessions: 10,
        nightCheckIn: true,
      ));
      Map<String, bool> unlocked = {for (final b in badges) b.id: b.unlocked};
      expect(unlocked['first_check_in'], isTrue);
      expect(unlocked['zen_streak'], isTrue);
      expect(unlocked['deep_breather'], isTrue);
      expect(unlocked['night_owl'], isTrue);
      expect(unlocked['mochi_fav'], isFalse);
      final fav = badges.firstWhere((b) => b.id == 'mochi_fav');
      expect(fav.current, 12);
      expect(fav.target, 50);
    });
  });
}
