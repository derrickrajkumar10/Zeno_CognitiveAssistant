class CogniPulseReading {
  final DateTime date;
  final int score;
  final double stressIndex;
  final double focusLevel;
  final double moodScore;

  const CogniPulseReading({
    required this.date,
    required this.score,
    required this.stressIndex,
    required this.focusLevel,
    required this.moodScore,
  });
}
