/// Picks the game Mochi suggests from today's readings (all 0–100).
class GameRecommender {
  GameRecommender._();

  static String recommend({
    required int score,
    double? stress,
    double? mood,
    double? focus,
  }) {
    if ((stress ?? 0) >= 70 || score < 30) {
      return 'wave_sync';
    }
    if (focus != null && focus < 30) {
      return 'focus_flicker';
    }
    if (mood != null && mood < 40) {
      return 'memory_garden';
    }
    return 'bubble_drift';
  }
}
