/// The measured inputs that feed the CogniPulse score.
///
/// Phone usage (30% in the PRD) is deliberately absent: this build does not
/// read OS usage stats, so it never produces a reading.
enum SignalType { selfReport, typing, faceScan, game }

extension SignalTypeX on SignalType {
  String get label {
    switch (this) {
      case SignalType.selfReport:
        return 'Mood check-in';
      case SignalType.typing:
        return 'Typing check-in';
      case SignalType.faceScan:
        return 'Face scan';
      case SignalType.game:
        return 'Game play';
    }
  }
}

/// One 0–100 reading from a single signal at a point in time.
///
/// [stress] and [mood] are optional 0–100 sub-scores used by the Insights
/// charts; a signal only fills the ones it actually measures.
class SignalReading {
  final SignalType type;
  final int score;
  final DateTime at;
  final double? stress;
  final double? mood;
  final String? note;

  const SignalReading({
    required this.type,
    required this.score,
    required this.at,
    this.stress,
    this.mood,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'score': score,
        'at': at.toIso8601String(),
        'stress': stress,
        'mood': mood,
        'note': note,
      };

  /// Returns null for rows this build does not understand.
  static SignalReading? fromMap(Map<String, dynamic> map) {
    final type = SignalType.values
        .where((value) => value.name == map['type'])
        .firstOrNull;
    final score = map['score'];
    final at = DateTime.tryParse(map['at'] as String? ?? '');
    if (type == null || score is! num || at == null) {
      return null;
    }
    return SignalReading(
      type: type,
      score: score.toInt().clamp(0, 100),
      at: at,
      stress: (map['stress'] as num?)?.toDouble(),
      mood: (map['mood'] as num?)?.toDouble(),
      note: map['note'] as String?,
    );
  }
}
