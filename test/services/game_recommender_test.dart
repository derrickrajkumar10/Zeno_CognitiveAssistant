import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/services/game_recommender.dart';

void main() {
  test('high stress or a low score suggests calming Wave Sync', () {
    expect(GameRecommender.recommend(score: 70, stress: 75), 'wave_sync');
    expect(GameRecommender.recommend(score: 25), 'wave_sync');
  });

  test('low focus suggests Focus Flicker', () {
    expect(GameRecommender.recommend(score: 60, focus: 20), 'focus_flicker');
  });

  test('low mood suggests Memory Garden', () {
    expect(GameRecommender.recommend(score: 60, mood: 30), 'memory_garden');
  });

  test('no worrying signal suggests playful Bubble Drift', () {
    expect(GameRecommender.recommend(score: 60), 'bubble_drift');
  });
}
