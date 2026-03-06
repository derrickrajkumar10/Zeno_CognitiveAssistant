class CogniPulseReading {
  final DateTime date;
  final int score;
  final double stressIndex;
  final double focusLevel;
  final double moodScore;
  final String source;
  final String? note;

  const CogniPulseReading({
    required this.date,
    required this.score,
    required this.stressIndex,
    required this.focusLevel,
    required this.moodScore,
    this.source = 'mock',
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'score': score,
        'stress_index': stressIndex,
        'focus_level': focusLevel,
        'mood_score': moodScore,
        'source': source,
        'note': note,
      };

  factory CogniPulseReading.fromMap(Map<String, dynamic> map) => CogniPulseReading(
        date: DateTime.parse(map['date'] as String),
        score: (map['score'] as num).toInt(),
        stressIndex: (map['stress_index'] as num).toDouble(),
        focusLevel: (map['focus_level'] as num).toDouble(),
        moodScore: (map['mood_score'] as num).toDouble(),
        source: map['source'] as String? ?? 'mock',
        note: map['note'] as String?,
      );
}
