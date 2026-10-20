/// One XP award. The ledger of these is the single source of truth for
/// total XP, today's XP, level and which quests are done today.
class XpEvent {
  /// 'quest', 'game', 'mood', 'typing' or 'face_scan'.
  final String source;

  /// Quest id or game id, when the source has one.
  final String? sourceId;
  final int amount;
  final DateTime at;

  const XpEvent({
    required this.source,
    required this.amount,
    required this.at,
    this.sourceId,
  });

  Map<String, dynamic> toMap() => {
        'source': source,
        'source_id': sourceId,
        'amount': amount,
        'at': at.toIso8601String(),
      };

  static XpEvent? fromMap(Map<String, dynamic> map) {
    final source = map['source'];
    final amount = map['amount'];
    final at = DateTime.tryParse(map['at'] as String? ?? '');
    if (source is! String || amount is! num || at == null) {
      return null;
    }
    return XpEvent(
      source: source,
      sourceId: map['source_id'] as String?,
      amount: amount.toInt(),
      at: at,
    );
  }
}
