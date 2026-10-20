import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/baseline.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/models/xp_event.dart';

/// On-device storage for everything the user has done: signal readings,
/// the XP ledger, the baseline questionnaire, simple counters and the name.
///
/// Every loader tolerates missing or corrupt data and returns an empty value
/// so a bad write can never stop the app from starting.
class WellnessRepository {
  static const signalsKey = 'zeno.signals';
  static const xpEventsKey = 'zeno.xp_events';
  static const baselineKey = 'zeno.baseline';
  static const countersKey = 'zeno.counters';
  static const userNameKey = 'zeno.user_name';

  /// Readings older than this are dropped on save.
  static const retention = Duration(days: 60);

  final SharedPreferences _prefs;

  WellnessRepository(this._prefs);

  List<SignalReading> loadSignals() => _loadList(signalsKey, SignalReading.fromMap)
    ..sort((a, b) => a.at.compareTo(b.at));

  Future<void> saveSignals(List<SignalReading> signals) {
    final cutoff = DateTime.now().subtract(retention);
    final kept = signals.where((s) => s.at.isAfter(cutoff));
    return _prefs.setString(
      signalsKey,
      jsonEncode(kept.map((s) => s.toMap()).toList(growable: false)),
    );
  }

  List<XpEvent> loadXpEvents() => _loadList(xpEventsKey, XpEvent.fromMap);

  Future<void> saveXpEvents(List<XpEvent> events) => _prefs.setString(
        xpEventsKey,
        jsonEncode(events.map((e) => e.toMap()).toList(growable: false)),
      );

  BaselineResult? loadBaseline() {
    final decoded = _decode(baselineKey);
    if (decoded is! Map) {
      return null;
    }
    return BaselineResult.fromMap(_stringKeys(decoded));
  }

  Future<void> saveBaseline(BaselineResult baseline) =>
      _prefs.setString(baselineKey, jsonEncode(baseline.toMap()));

  Map<String, int> loadCounters() {
    final decoded = _decode(countersKey);
    if (decoded is! Map) {
      return {};
    }
    return {
      for (final entry in decoded.entries)
        if (entry.value is num) entry.key.toString(): (entry.value as num).toInt(),
    };
  }

  Future<void> saveCounters(Map<String, int> counters) =>
      _prefs.setString(countersKey, jsonEncode(counters));

  String? loadUserName() => _prefs.getString(userNameKey);

  Future<void> saveUserName(String name) => _prefs.setString(userNameKey, name);

  List<T> _loadList<T>(String key, T? Function(Map<String, dynamic>) parse) {
    final decoded = _decode(key);
    if (decoded is! List) {
      return <T>[];
    }
    final items = <T>[];
    for (final row in decoded.whereType<Map>()) {
      try {
        final item = parse(_stringKeys(row));
        if (item != null) {
          items.add(item);
        }
      } catch (error) {
        debugPrint('WellnessRepository skipped a bad $key row: $error');
      }
    }
    return items;
  }

  Object? _decode(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } catch (error) {
      debugPrint('WellnessRepository could not read $key: $error');
      return null;
    }
  }

  Map<String, dynamic> _stringKeys(Map map) =>
      map.map((key, value) => MapEntry(key.toString(), value));
}
