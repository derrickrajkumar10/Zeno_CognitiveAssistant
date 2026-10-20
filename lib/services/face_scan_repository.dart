import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/face_scan_entry.dart';

class FaceScanRepository {
  static const storageKey = 'zeno.face_scan_history';

  final SharedPreferences _prefs;

  FaceScanRepository(this._prefs);

  /// Unreadable history, or rows from an older format, are skipped rather
  /// than stopping the app from starting.
  List<FaceScanEntry> loadHistory() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (error) {
      debugPrint('FaceScanRepository could not read history: $error');
      return const [];
    }
    if (decoded is! List) {
      return const [];
    }
    final scans = <FaceScanEntry>[];
    for (final entry in decoded.whereType<Map>()) {
      try {
        scans.add(FaceScanEntry.fromMap(
          entry.map((key, value) => MapEntry(key.toString(), value)),
        ));
      } catch (error) {
        debugPrint('FaceScanRepository skipped a bad scan: $error');
      }
    }
    scans.sort((left, right) => right.scannedAt.compareTo(left.scannedAt));
    return scans;
  }

  Future<void> saveHistory(List<FaceScanEntry> scans) async {
    final payload = scans.map((scan) => scan.toMap()).toList(growable: false);
    await _prefs.setString(storageKey, jsonEncode(payload));
  }
}
