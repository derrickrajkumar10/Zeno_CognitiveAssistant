class Badge {
  final String id;
  final String name;
  final String icon;
  final String description;
  final int current;
  final int target;

  const Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.current,
    required this.target,
  });

  bool get unlocked => current >= target;

  double get progress => target == 0 ? 1 : (current / target).clamp(0.0, 1.0);
}

/// The user's progress, derived from the XP ledger and check-in history.
class UserProfile {
  final String name;
  final int level;

  /// XP earned inside the current level.
  final int xp;
  final int xpToNextLevel;
  final int currentStreak;
  final int longestStreak;
  final int totalQuestsCompleted;

  /// Mean of the last 7 days that have check-ins; null when there are none.
  final double? avgCogniPulse;
  final List<Badge> badges;

  const UserProfile({
    required this.name,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalQuestsCompleted,
    required this.avgCogniPulse,
    required this.badges,
  });
}
