class Badge {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool unlocked;

  const Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.unlocked,
  });
}

class UserProfile {
  final String name;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int currentStreak;
  final int totalQuestsCompleted;
  final double avgCogniPulse;
  final String avatarId;
  final List<Badge> badges;

  const UserProfile({
    required this.name,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.currentStreak,
    required this.totalQuestsCompleted,
    required this.avgCogniPulse,
    required this.avatarId,
    required this.badges,
  });
}
