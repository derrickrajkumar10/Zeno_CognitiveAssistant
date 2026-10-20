import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/services/face_scan_analyzer.dart';

FaceFrameSignal _frame({
  double smile = 1,
  double leftEye = 1,
  double rightEye = 1,
  double yaw = 0,
  double roll = 0,
  double centred = 1,
}) {
  return FaceFrameSignal(
    smileProbability: smile,
    leftEyeOpenProbability: leftEye,
    rightEyeOpenProbability: rightEye,
    headEulerAngleY: yaw,
    headEulerAngleZ: roll,
    centeredness: centred,
  );
}

void main() {
  final analyzer = FaceScanAnalyzer();
  final at = DateTime(2026, 10, 20, 9, 30);

  test('a smiling, still, centred face scores at the top', () {
    final entry = analyzer.buildEntry(
      samples: List.filled(10, _frame()),
      framesProcessed: 10,
      scannedAt: at,
    );

    expect(entry.moodScore, 100);
    expect(entry.focusLevel, 100);
    expect(entry.stressIndex, 0);
    expect(entry.score, 100);
    expect(entry.scannedAt, at);
    expect(entry.faceDetectedFrames, 10);
    expect(entry.mochiInsight, contains('steadiness'));
  });

  test('no smile, half-closed eyes and a turned head read as stressed', () {
    final calm = analyzer.buildEntry(
      samples: List.filled(10, _frame()),
      framesProcessed: 10,
    );
    final tense = analyzer.buildEntry(
      samples: List.filled(
        10,
        _frame(smile: 0, leftEye: 0.5, rightEye: 0.5, yaw: 35, roll: 25, centred: 0.5),
      ),
      framesProcessed: 10,
    );

    // 100 - (0 + 0.5*18 + 0 + 0 + 0.5*10 + 1*10) = 76
    expect(tense.stressIndex, closeTo(76, 0.001));
    expect(tense.moodScore, closeTo(40, 0.001));
    expect(tense.score, lessThan(calm.score));
    expect(tense.mochiInsight, contains('wound up'));
  });

  test('a scan that never saw a face stays in range and says so', () {
    final entry = analyzer.buildEntry(samples: const [], framesProcessed: 30);

    for (final value in [entry.moodScore, entry.focusLevel, entry.stressIndex]) {
      expect(value.isFinite, isTrue);
      expect(value, inInclusiveRange(0, 100));
    }
    expect(entry.score, inInclusiveRange(0, 100));
    expect(entry.faceCoverage, 0);
    expect(entry.mochiInsight, contains('only caught part'));
  });

  test('zero processed frames does not divide by zero', () {
    final entry = analyzer.buildEntry(samples: const [], framesProcessed: 0);
    expect(entry.faceCoverage, 0);
    expect(entry.score, inInclusiveRange(0, 100));
  });

  test('turning left or right counts the same', () {
    final left = analyzer.buildEntry(
      samples: [_frame(yaw: -20, roll: -10)],
      framesProcessed: 1,
    );
    final right = analyzer.buildEntry(
      samples: [_frame(yaw: 20, roll: 10)],
      framesProcessed: 1,
    );
    expect(left.score, right.score);
    expect(left.headEulerAngleY, 20);
  });

  test('low coverage lowers the score even with a calm face', () {
    final full = analyzer.buildEntry(
      samples: List.filled(10, _frame()),
      framesProcessed: 10,
    );
    final partial = analyzer.buildEntry(
      samples: List.filled(3, _frame()),
      framesProcessed: 10,
    );
    expect(partial.score, lessThan(full.score));
    expect(partial.mochiInsight, contains('only caught part'));
  });
}
