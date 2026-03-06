import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/face_scan_entry.dart';

class FaceScanRepository {
  static const storageKey = 'zeno.face_scan_history';

  final SharedPreferences _prefs;

  FaceScanRepository(this._prefs);

  List<FaceScanEntry> loadHistory() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    final scans = decoded
        .whereType<Map>()
        .map((entry) => FaceScanEntry.fromMap(
              entry.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();
    scans.sort((left, right) => right.scannedAt.compareTo(left.scannedAt));
    return scans;
  }

  Future<void> saveHistory(List<FaceScanEntry> scans) async {
    final payload = scans.map((scan) => scan.toMap()).toList(growable: false);
    await _prefs.setString(storageKey, jsonEncode(payload));
  }
}
