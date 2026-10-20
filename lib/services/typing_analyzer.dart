import 'dart:math' as math;

/// The outcome of one typing check-in.
class TypingResult {
  final int score;
  final double wpm;

  /// 1 − edit distance / length, 0–1.
  final double accuracy;

  /// Backspaces per keystroke, ×4, capped at 1.
  final double correctionRate;

  /// Share of gaps between keystrokes longer than 1.5 s.
  final double pauseRatio;

  const TypingResult({
    required this.score,
    required this.wpm,
    required this.accuracy,
    required this.correctionRate,
    required this.pauseRatio,
  });

  double get stress => (100 - score).toDouble();

  String get note => '${wpm.round()} wpm · ${(accuracy * 100).round()}% accurate';
}

/// Scores how someone types a practice sentence: speed, accuracy,
/// corrections and hesitation. Only timing and the practice sentence are
/// used; nothing the user types elsewhere is read.
class TypingAnalyzer {
  TypingAnalyzer._();

  /// Typing at or above this speed counts as full speed on a phone.
  static const fullSpeedWpm = 40.0;
  static const longPause = Duration(milliseconds: 1500);

  static TypingResult? analyze({
    required String target,
    required String typed,
    required List<DateTime> keystrokes,
    required int backspaces,
  }) {
    final text = typed.trim();
    if (text.isEmpty || keystrokes.length < 2) {
      return null;
    }

    final elapsed = keystrokes.last.difference(keystrokes.first);
    final minutes = math.max(elapsed.inMilliseconds, 1000) / 60000;
    final wpm = (text.length / 5) / minutes;

    final longest = math.max(target.length, text.length);
    final accuracy = (1 - _editDistance(text, target) / longest).clamp(0.0, 1.0);

    final correctionRate = (backspaces / keystrokes.length * 4).clamp(0.0, 1.0);

    var pauses = 0;
    for (var i = 1; i < keystrokes.length; i++) {
      if (keystrokes[i].difference(keystrokes[i - 1]) > longPause) {
        pauses++;
      }
    }
    final pauseRatio = pauses / (keystrokes.length - 1);

    final speed = math.min(1.0, wpm / fullSpeedWpm);
    final score = (100 *
            (0.35 * accuracy +
                0.25 * speed +
                0.25 * (1 - correctionRate) +
                0.15 * (1 - pauseRatio)))
        .round()
        .clamp(0, 100);

    return TypingResult(
      score: score,
      wpm: wpm,
      accuracy: accuracy,
      correctionRate: correctionRate,
      pauseRatio: pauseRatio,
    );
  }

  /// Levenshtein distance, two-row version.
  static int _editDistance(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
      }
      previous = current;
    }
    return previous[b.length];
  }
}
