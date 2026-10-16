/// Answers to the five onboarding questions, each 1–5 where 5 is the
/// healthiest answer (the stress question is asked so that 5 = "rarely").
///
/// Order: stress, sleep, focus, mood, energy.
class BaselineResult {
  static const questionCount = 5;

  final List<int> answers;
  final DateTime at;

  const BaselineResult({required this.answers, required this.at});

  static double _toPercent(int answer) => (answer.clamp(1, 5) - 1) / 4 * 100;

  int get score {
    final total = answers.fold<double>(0, (sum, a) => sum + _toPercent(a));
    return (total / answers.length).round();
  }

  double get stress => 100 - _toPercent(answers[0]);

  double get mood => _toPercent(answers[3]);

  Map<String, dynamic> toMap() => {
        'answers': answers,
        'at': at.toIso8601String(),
      };

  static BaselineResult? fromMap(Map<String, dynamic> map) {
    final answers = map['answers'];
    final at = DateTime.tryParse(map['at'] as String? ?? '');
    if (answers is! List ||
        answers.length != questionCount ||
        answers.any((a) => a is! num) ||
        at == null) {
      return null;
    }
    return BaselineResult(
      answers: answers.map((a) => (a as num).toInt()).toList(growable: false),
      at: at,
    );
  }
}
