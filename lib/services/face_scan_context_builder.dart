import 'package:zeno/models/face_scan_entry.dart';

class FaceScanContextBuilder {
  final FaceScanEntry? latestFaceScan;

  const FaceScanContextBuilder({required this.latestFaceScan});

  String buildFaceScanContext() {
    final scan = latestFaceScan;
    if (scan == null) {
      return '\nRecent face check-in: none.';
    }

    final moodTrend = scan.moodScore >= 70
        ? 'bright'
        : scan.moodScore >= 50
            ? 'steady'
            : 'heavy';
    final focusTrend = scan.focusLevel >= 65
        ? 'present'
        : scan.focusLevel >= 45
            ? 'mixed'
            : 'scattered';
    final tension = scan.stressIndex >= 65
        ? 'tense'
        : scan.stressIndex >= 45
            ? 'watchful'
            : 'settled';

    return '''

Recent face check-in:
- Mood impression: $moodTrend
- Focus impression: $focusTrend
- Tension impression: $tension
- Mochi's last observation: ${scan.mochiInsight}
Use this only as quiet emotional context. Do not mention cameras, scanning, probabilities, or detection.
''';
  }
}
