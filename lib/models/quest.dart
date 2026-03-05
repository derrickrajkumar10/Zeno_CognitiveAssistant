enum QuestStatus { available, inProgress, completed }

class Quest {
  final String id;
  final String title;
  final String icon;
  final int xpReward;
  final String duration;
  final String description;
  QuestStatus status;

  Quest({
    required this.id,
    required this.title,
    required this.icon,
    required this.xpReward,
    required this.duration,
    required this.description,
    this.status = QuestStatus.available,
  });

  Quest copyWith({QuestStatus? status}) => Quest(
    id: id, title: title, icon: icon, xpReward: xpReward,
    duration: duration, description: description,
    status: status ?? this.status,
  );
}
