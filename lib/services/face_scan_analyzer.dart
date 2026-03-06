import 'dart:math' as math;

import 'package:uuid/uuid.dart';
import 'package:zeno/models/face_scan_entry.dart';

class FaceFrameSignal {
  final double smileProbability;
  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;
  final double headEulerAngleY;
  final double headEulerAngleZ;
  final double centeredness;

  const FaceFrameSignal({
    required this.smileProbability,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.centeredness,
  });
}

class FaceScanAnalyzer {
  static const _uuid = Uuid();

  FaceScanEntry buildEntry({
    required List<FaceFrameSignal> samples,
    required int framesProcessed,
    DateTime? scannedAt,
  }) {
    final when = scannedAt ?? DateTime.now();
    final avgSmile = _average(samples.map((sample) => sample.smileProbability));
    final avgLeftEye =
        _average(samples.map((sample) => sample.leftEyeOpenProbability));
    final avgRightEye =
        _average(samples.map((sample) => sample.rightEyeOpenProbability));
    final avgYaw = _average(samples.map((sample) => sample.headEulerAngleY.abs()));
    final avgRoll = _average(samples.map((sample) => sample.headEulerAngleZ.abs()));
    final avgCentered = _average(samples.map((sample) => sample.centeredness));
    final eyeAverage = (avgLeftEye + avgRightEye) / 2;
    final yawStability = 1 - (avgYaw / 35).clamp(0.0, 1.0);
    final rollStability = 1 - (avgRoll / 25).clamp(0.0, 1.0);
    final coverage = framesProcessed == 0 ? 0.0 : samples.length / framesProcessed;

    final moodScore =
        _clampTo100(30 + avgSmile * 55 + avgCentered * 10 + coverage * 5);
    final focusLevel = _clampTo100(
      30 + eyeAverage * 45 + yawStability * 15 + avgCentered * 10,
    );
    final stressIndex = _clampTo100(
      100 -
          (avgSmile * 28 +
              eyeAverage * 18 +
              yawStability * 20 +
              rollStability * 14 +
              avgCentered * 10 +
              coverage * 10),
    );
    final score = _clampTo100(
      moodScore * 0.34 + focusLevel * 0.33 + (100 - stressIndex) * 0.33,
    ).round();

    return FaceScanEntry(
      id: _uuid.v4(),
      scannedAt: when,
      score: score,
      stressIndex: stressIndex,
      focusLevel: focusLevel,
      moodScore: moodScore,
      smileProbability: avgSmile,
      leftEyeOpenProbability: avgLeftEye,
      rightEyeOpenProbability: avgRightEye,
      headEulerAngleY: avgYaw,
      headEulerAngleZ: avgRoll,
      faceDetectedFrames: samples.length,
      framesProcessed: framesProcessed,
      mochiInsight: _buildInsight(
        moodScore: moodScore,
        focusLevel: focusLevel,
        stressIndex: stressIndex,
        coverage: coverage,
      ),
    );
  }

  double _average(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return 0;
    }
    return list.reduce((left, right) => left + right) / list.length;
  }

  double _clampTo100(double value) => math.max(0, math.min(100, value));

  String _buildInsight({
    required double moodScore,
    required double focusLevel,
    required double stressIndex,
    required double coverage,
  }) {
    if (coverage < 0.45) {
      return 'Mochi only caught part of you that time, but still sensed a quiet check-in.';
    }
    if (stressIndex >= 65) {
      return 'Mochi thinks you look a little wound up. Something softer would help right now.';
    }
    if (focusLevel < 45) {
      return 'Mochi sees a scattered kind of tired. A short reset could bring you back together.';
    }
    if (moodScore >= 72 && focusLevel >= 60) {
      return 'Mochi likes this look on you. There is steadiness here, and a bit of light too.';
    }
    if (moodScore < 45) {
      return 'Mochi sees a heavier moment. Gentle pace, gentle expectations.';
    }
    return 'Mochi sees you settling into the moment. Not perfect, just honest.';
  }
}
