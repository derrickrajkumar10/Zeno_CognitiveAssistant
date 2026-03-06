import 'package:zeno/models/cognipulse_reading.dart';

class FaceScanEntry {
  final String id;
  final DateTime scannedAt;
  final int score;
  final double stressIndex;
  final double focusLevel;
  final double moodScore;
  final double smileProbability;
  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;
  final double headEulerAngleY;
  final double headEulerAngleZ;
  final int faceDetectedFrames;
  final int framesProcessed;
  final String mochiInsight;

  const FaceScanEntry({
    required this.id,
    required this.scannedAt,
    required this.score,
    required this.stressIndex,
    required this.focusLevel,
    required this.moodScore,
    required this.smileProbability,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
    required this.headEulerAngleY,
    required this.headEulerAngleZ,
    required this.faceDetectedFrames,
    required this.framesProcessed,
    required this.mochiInsight,
  });

  double get eyeOpenAverage =>
      (leftEyeOpenProbability + rightEyeOpenProbability) / 2;

  double get faceCoverage =>
      framesProcessed == 0 ? 0 : faceDetectedFrames / framesProcessed;

  CogniPulseReading toReading() => CogniPulseReading(
        date: scannedAt,
        score: score,
        stressIndex: stressIndex,
        focusLevel: focusLevel,
        moodScore: moodScore,
        source: 'face_scan',
        note: mochiInsight,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'scanned_at': scannedAt.toIso8601String(),
        'score': score,
        'stress_index': stressIndex,
        'focus_level': focusLevel,
        'mood_score': moodScore,
        'smile_probability': smileProbability,
        'left_eye_open_probability': leftEyeOpenProbability,
        'right_eye_open_probability': rightEyeOpenProbability,
        'head_euler_angle_y': headEulerAngleY,
        'head_euler_angle_z': headEulerAngleZ,
        'face_detected_frames': faceDetectedFrames,
        'frames_processed': framesProcessed,
        'mochi_insight': mochiInsight,
      };

  factory FaceScanEntry.fromMap(Map<String, dynamic> map) => FaceScanEntry(
        id: map['id'] as String,
        scannedAt: DateTime.parse(map['scanned_at'] as String),
        score: (map['score'] as num).toInt(),
        stressIndex: (map['stress_index'] as num).toDouble(),
        focusLevel: (map['focus_level'] as num).toDouble(),
        moodScore: (map['mood_score'] as num).toDouble(),
        smileProbability: (map['smile_probability'] as num).toDouble(),
        leftEyeOpenProbability:
            (map['left_eye_open_probability'] as num).toDouble(),
        rightEyeOpenProbability:
            (map['right_eye_open_probability'] as num).toDouble(),
        headEulerAngleY: (map['head_euler_angle_y'] as num).toDouble(),
        headEulerAngleZ: (map['head_euler_angle_z'] as num).toDouble(),
        faceDetectedFrames: (map['face_detected_frames'] as num).toInt(),
        framesProcessed: (map['frames_processed'] as num).toInt(),
        mochiInsight: map['mochi_insight'] as String,
      );
}
