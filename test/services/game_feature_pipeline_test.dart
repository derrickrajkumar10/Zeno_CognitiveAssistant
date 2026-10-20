import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/services/game_feature_pipeline.dart';

class _FixedPipeline extends GameFeaturePipeline {
  final GameFeatureVector vector;
  _FixedPipeline(this.vector);

  @override
  Future<GameFeatureVector> compute(String userId) async => vector;
}

Future<int> _adjustmentFor(GameFeatureVector vector) {
  return CogniPulseGameContributor(pipeline: _FixedPipeline(vector))
      .computeAdjustment('alex');
}

void main() {
  group('CogniPulseGameContributor', () {
    test('no game data leaves the score unchanged', () async {
      expect(await _adjustmentFor(const GameFeatureVector()), 0);
    });

    test('slow, error-prone, hesitant play lowers the score', () async {
      const stressed = GameFeatureVector(
        reactionMsZScore: 1.5,
        pressureVarianceZScore: 1.8,
        errorRateZScore: 1.3,
        hesitationIndexZScore: 1.0,
        sessionCompletionRate: 0.55,
        memoryScoreZScore: -1.1,
        flexibilityRecoveryMs: 1.4,
        ruminationEventCount: 3,
      );
      expect(await _adjustmentFor(stressed), lessThan(0));
    });

    test('fast, accurate, focused play raises the score', () async {
      const focused = GameFeatureVector(
        reactionMsZScore: -1.0,
        pressureVarianceZScore: -0.8,
        errorRateZScore: -1.2,
        hesitationIndexZScore: -0.9,
        sessionCompletionRate: 0.92,
        memoryScoreZScore: 0.8,
        flexibilityRecoveryMs: -0.7,
      );
      expect(await _adjustmentFor(focused), greaterThan(0));
    });

    test('better memory accuracy and less late-game fatigue lower stress load',
        () {
      const sharp = GameFeatureVector(
        memoryScoreZScore: 1.0,
        fatigueCurveDropIndex: 1.0,
      );
      const dull = GameFeatureVector(
        memoryScoreZScore: -1.0,
        fatigueCurveDropIndex: -1.0,
      );
      expect(sharp.stressLoad, lessThan(dull.stressLoad));
    });

    test('a single session can move the score by at most 15 points', () async {
      const extreme = GameFeatureVector(
        reactionMsZScore: 50,
        errorRateZScore: 50,
        pressureVarianceZScore: 50,
      );
      expect(await _adjustmentFor(extreme), -15);
    });
  });

  group('CogniPulseGameContributor.computeSignalScore', () {
    Future<int> signalFor(GameFeatureVector vector) =>
        CogniPulseGameContributor(pipeline: _FixedPipeline(vector))
            .computeSignalScore('alex');

    test('play that matches your own baseline reads as a neutral 60', () async {
      expect(await signalFor(const GameFeatureVector()), 60);
    });

    test('strained play reads below 60, sharp play above', () async {
      expect(
        await signalFor(const GameFeatureVector(reactionMsZScore: 2, errorRateZScore: 2)),
        lessThan(60),
      );
      expect(
        await signalFor(const GameFeatureVector(reactionMsZScore: -2, errorRateZScore: -2)),
        greaterThan(60),
      );
    });

    test('the signal stays between 30 and 90', () async {
      expect(await signalFor(const GameFeatureVector(reactionMsZScore: 99)), 30);
      expect(await signalFor(const GameFeatureVector(reactionMsZScore: -99)), 90);
    });
  });
}
