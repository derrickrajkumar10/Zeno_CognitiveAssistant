import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/models/face_scan_entry.dart';
import 'package:zeno/models/signal_reading.dart';

void main() {
  final entry = FaceScanEntry(
    id: 'scan-1',
    scannedAt: DateTime(2026, 10, 20, 8),
    score: 71,
    stressIndex: 32.5,
    focusLevel: 66,
    moodScore: 74,
    smileProbability: 0.6,
    leftEyeOpenProbability: 0.9,
    rightEyeOpenProbability: 0.7,
    headEulerAngleY: 4,
    headEulerAngleZ: 2,
    faceDetectedFrames: 24,
    framesProcessed: 30,
    mochiInsight: 'Mochi sees you settling into the moment.',
  );

  test('survives a round trip through storage', () {
    final copy = FaceScanEntry.fromMap(entry.toMap());
    expect(copy.toMap(), entry.toMap());
  });

  test('becomes a face-scan signal for CogniPulse', () {
    final signal = entry.toSignal();
    expect(signal.type, SignalType.faceScan);
    expect(signal.score, 71);
    expect(signal.stress, 32.5);
    expect(signal.mood, 74);
    expect(signal.at, entry.scannedAt);
  });

  test('averages the eyes and reports face coverage', () {
    expect(entry.eyeOpenAverage, closeTo(0.8, 1e-9));
    expect(entry.faceCoverage, closeTo(0.8, 1e-9));
  });
}
