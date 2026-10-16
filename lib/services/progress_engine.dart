import 'package:zeno/models/user_profile.dart';

/// Real counts behind each badge.
class BadgeStats {
  final int checkIns;
  final int earlyCheckInDays;
  final int longestStreak;
  final int mochiTaps;
  final int daysAbove80;
  final int breathingSessions;
  final bool nightCheckIn;

  const BadgeStats({
    this.checkIns = 0,
    this.earlyCheckInDays = 0,
    this.longestStreak = 0,
    this.mochiTaps = 0,
    this.daysAbove80 = 0,
    this.breathingSessions = 0,
    this.nightCheckIn = false,
  });
}

/// Pure rules for levels, streaks and badges.
class ProgressEngine {
  ProgressEngine._();

  static const xpPerLevel = 250;

  static int level(int totalXp) => totalXp ~/ xpPerLevel + 1;

  static int xpIntoLevel(int totalXp) => totalXp % xpPerLevel;

  /// Consecutive active days ending today, or ending yesterday when today
  /// has no activity yet (the streak is still alive until today ends).
  static int currentStreak(Set<DateTime> activeDays, DateTime now) {
    final days = activeDays.map(_dateOnly).toSet();
    var cursor = _dateOnly(now);
    if (!days.contains(cursor)) {
      cursor = _previousDay(cursor);
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = _previousDay(cursor);
    }
    return streak;
  }

  static int longestStreak(Set<DateTime> activeDays) {
    final days = activeDays.map(_dateOnly).toSet();
    var best = 0;
    for (final day in days) {
      if (days.contains(_previousDay(day))) {
        continue; // not the start of a run
      }
      var length = 0;
      var cursor = day;
      while (days.contains(cursor)) {
        length++;
        cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
      }
      if (length > best) {
        best = length;
      }
    }
    return best;
  }

  static List<Badge> badges(BadgeStats stats) => [
        Badge(
          id: 'first_check_in',
          name: 'First Check-In',
          icon: '🌱',
          description: 'Log your first mood, typing or face check-in',
          current: stats.checkIns,
          target: 1,
        ),
        Badge(
          id: 'early_bird',
          name: 'Early Bird',
          icon: '🌅',
          description: 'Check in before 8am on 3 different days',
          current: stats.earlyCheckInDays,
          target: 3,
        ),
        Badge(
          id: 'zen_streak',
          name: 'Zen Streak',
          icon: '🧘',
          description: 'Be active 5 days in a row',
          current: stats.longestStreak,
          target: 5,
        ),
        Badge(
          id: 'mochi_fav',
          name: "Mochi's Favourite",
          icon: '🐾',
          description: 'Tap Mochi 50 times',
          current: stats.mochiTaps,
          target: 50,
        ),
        Badge(
          id: 'brain_boost',
          name: 'Brain Boost',
          icon: '⚡',
          description: 'Reach a CogniPulse of 80+ on 3 days',
          current: stats.daysAbove80,
          target: 3,
        ),
        Badge(
          id: 'deep_breather',
          name: 'Deep Breather',
          icon: '💨',
          description: 'Finish 10 box-breathing sessions',
          current: stats.breathingSessions,
          target: 10,
        ),
        Badge(
          id: 'night_owl',
          name: 'Night Owl',
          icon: '🦉',
          description: 'Check in after 11pm',
          current: stats.nightCheckIn ? 1 : 0,
          target: 1,
        ),
      ];

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  // Calendar arithmetic, not Duration, so DST changes never skip a day.
  static DateTime _previousDay(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);
}
