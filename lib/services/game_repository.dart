import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:zeno/models/game_session.dart';
import 'package:zeno/models/game_touch_event.dart';

/// Persistent storage for game sessions, baselines, and local-only touch logs.
class GameRepository {
  static const _sessionsPrefsKey = 'zeno.game_sessions';
  static const _baselinesPrefsKey = 'zeno.game_baselines';
  static const _touchEventsPrefsKey = 'zeno.game_touch_events';

  GameRepository._();
  static final GameRepository _instance = GameRepository._();
  factory GameRepository() => _instance;

  Database? _db;
  SharedPreferences? _prefs;
  bool? _usePrefs;

  Future<bool> _shouldUsePrefs() async {
    if (_usePrefs != null) {
      return _usePrefs!;
    }
    if (kIsWeb) {
      _usePrefs = true;
      return true;
    }
    try {
      _db ??= await _initDb();
      _usePrefs = false;
      return false;
    } catch (error, stackTrace) {
      debugPrint('GameRepository falling back to SharedPreferences: $error');
      debugPrintStack(stackTrace: stackTrace);
      _usePrefs = true;
      return true;
    }
  }

  Future<SharedPreferences> get _preferences async {
    if (_prefs != null) {
      return _prefs!;
    }
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Database> get database async {
    if (await _shouldUsePrefs()) {
      throw UnsupportedError('SQLite is unavailable on this platform');
    }
    if (_db != null) {
      return _db!;
    }
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final databasePath = join(dbPath, 'zeno_games.db');
    return openDatabase(
      databasePath,
      version: 2,
      onCreate: (db, version) => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) => _createTables(db),
      onOpen: (db) => _createTables(db),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        game_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT NOT NULL,
        session_length_sec INTEGER NOT NULL,
        avg_reaction_ms REAL NOT NULL,
        avg_pressure REAL NOT NULL,
        pressure_variance REAL NOT NULL,
        error_rate REAL NOT NULL,
        hesitation_index REAL NOT NULL,
        level_reached INTEGER NOT NULL,
        drop_off_early INTEGER NOT NULL DEFAULT 0,
        reaction_delta REAL NOT NULL DEFAULT 0,
        pressure_delta REAL NOT NULL DEFAULT 0,
        error_delta REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_baselines (
        user_id TEXT NOT NULL,
        game_id TEXT NOT NULL,
        baseline_reaction_ms REAL NOT NULL,
        baseline_pressure REAL NOT NULL,
        baseline_error_rate REAL NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (user_id, game_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_touch_events (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        game_id TEXT NOT NULL,
        reaction_time_ms INTEGER NOT NULL,
        tap_pressure REAL NOT NULL,
        tap_x REAL NOT NULL,
        tap_y REAL NOT NULL,
        event_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        game_context_json TEXT NOT NULL
      )
    ''');
  }

  /// Deletes every stored session, baseline and touch event.
  Future<void> clearAll() async {
    if (await _shouldUsePrefs()) {
      final prefs = await _preferences;
      for (final key in [_sessionsPrefsKey, _baselinesPrefsKey, _touchEventsPrefsKey]) {
        await prefs.remove(key);
      }
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('game_sessions');
      await txn.delete('game_baselines');
      await txn.delete('game_touch_events');
    });
  }

  Future<void> saveSession(GameSession session) async {
    if (await _shouldUsePrefs()) {
      final rows = await _readPrefsRows(_sessionsPrefsKey);
      _upsertRow(rows, session.toMap());
      await _writePrefsRows(_sessionsPrefsKey, rows);
      return;
    }
    final db = await database;
    await db.insert(
      'game_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveTouchEvents(List<GameTouchEventRecord> events) async {
    if (events.isEmpty) {
      return;
    }
    if (await _shouldUsePrefs()) {
      final rows = await _readPrefsRows(_touchEventsPrefsKey);
      for (final event in events) {
        _upsertRow(rows, event.toMap());
      }
      await _writePrefsRows(_touchEventsPrefsKey, rows);
      return;
    }
    final db = await database;
    final batch = db.batch();
    for (final event in events) {
      batch.insert(
        'game_touch_events',
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<GameBaseline?> getBaseline(String userId, String gameId) async {
    if (await _shouldUsePrefs()) {
      final rows = await _readPrefsRows(_baselinesPrefsKey);
      for (final row in rows) {
        if (row['user_id'] == userId && row['game_id'] == gameId) {
          return GameBaseline.fromMap(row);
        }
      }
      return null;
    }
    final db = await database;
    final rows = await db.query(
      'game_baselines',
      where: 'user_id = ? AND game_id = ?',
      whereArgs: [userId, gameId],
    );
    if (rows.isEmpty) {
      return null;
    }
    return GameBaseline.fromMap(rows.first);
  }

  Future<void> updateBaseline(String userId, String gameId) async {
    final gameSessions = await getRecentGameSessions(userId, gameId, days: 7);
    if (gameSessions.isEmpty) {
      return;
    }

    final avgReaction = gameSessions.fold<double>(
          0,
          (sum, session) => sum + session.avgReactionMs,
        ) /
        gameSessions.length;
    final avgPressure = gameSessions.fold<double>(
          0,
          (sum, session) => sum + session.avgPressure,
        ) /
        gameSessions.length;
    final avgError = gameSessions.fold<double>(
          0,
          (sum, session) => sum + session.errorRate,
        ) /
        gameSessions.length;

    final baseline = GameBaseline(
      userId: userId,
      gameId: gameId,
      baselineReactionMs: avgReaction,
      baselinePressure: avgPressure,
      baselineErrorRate: avgError,
      updatedAt: DateTime.now(),
    );

    if (await _shouldUsePrefs()) {
      final rows = await _readPrefsRows(_baselinesPrefsKey);
      _upsertRow(rows, baseline.toMap(), idFields: const ['user_id', 'game_id']);
      await _writePrefsRows(_baselinesPrefsKey, rows);
      return;
    }
    final db = await database;
    await db.insert(
      'game_baselines',
      baseline.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GameSession>> getRecentSessions(String userId, {int days = 7}) async {
    if (await _shouldUsePrefs()) {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final rows = await _readPrefsRows(_sessionsPrefsKey);
      return rows
          .where(
            (row) =>
                row['user_id'] == userId &&
                DateTime.parse(row['started_at'] as String).isAfter(cutoff),
          )
          .map(GameSession.fromMap)
          .toList()
        ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    }
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.query(
      'game_sessions',
      where: 'user_id = ? AND started_at >= ?',
      whereArgs: [userId, cutoff],
      orderBy: 'started_at DESC',
    );
    return rows.map(GameSession.fromMap).toList();
  }

  Future<List<GameSession>> getRecentGameSessions(
    String userId,
    String gameId, {
    int days = 7,
  }) async {
    if (await _shouldUsePrefs()) {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final rows = await _readPrefsRows(_sessionsPrefsKey);
      return rows
          .where(
            (row) =>
                row['user_id'] == userId &&
                row['game_id'] == gameId &&
                DateTime.parse(row['started_at'] as String).isAfter(cutoff),
          )
          .map(GameSession.fromMap)
          .toList()
        ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    }
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.query(
      'game_sessions',
      where: 'user_id = ? AND game_id = ? AND started_at >= ?',
      whereArgs: [userId, gameId, cutoff],
      orderBy: 'started_at DESC',
    );
    return rows.map(GameSession.fromMap).toList();
  }

  Future<List<GameTouchEventRecord>> getRecentTouchEvents(
    String userId, {
    int days = 7,
    String? gameId,
  }) async {
    if (await _shouldUsePrefs()) {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final rows = await _readPrefsRows(_touchEventsPrefsKey);
      return rows
          .where(
            (row) =>
                row['user_id'] == userId &&
                (gameId == null || row['game_id'] == gameId) &&
                DateTime.parse(row['timestamp'] as String).isAfter(cutoff),
          )
          .map(GameTouchEventRecord.fromMap)
          .toList()
        ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
    }
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await db.query(
      'game_touch_events',
      where: gameId == null
          ? 'user_id = ? AND timestamp >= ?'
          : 'user_id = ? AND game_id = ? AND timestamp >= ?',
      whereArgs: gameId == null ? [userId, cutoff] : [userId, gameId, cutoff],
      orderBy: 'timestamp ASC',
    );
    return rows.map(GameTouchEventRecord.fromMap).toList();
  }

  Future<List<GameTouchEventRecord>> getTouchEventsForSessionIds(
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) {
      return const [];
    }
    if (await _shouldUsePrefs()) {
      final rows = await _readPrefsRows(_touchEventsPrefsKey);
      return rows
          .where((row) => sessionIds.contains(row['session_id']))
          .map(GameTouchEventRecord.fromMap)
          .toList()
        ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
    }
    final db = await database;
    final placeholders = List.filled(sessionIds.length, '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT * FROM game_touch_events WHERE session_id IN ($placeholders) ORDER BY timestamp ASC',
      sessionIds,
    );
    return rows.map(GameTouchEventRecord.fromMap).toList();
  }

  Future<DateTime?> getLastPlayedAt(String userId, String gameId) async {
    if (await _shouldUsePrefs()) {
      final sessions = await getRecentGameSessions(userId, gameId, days: 3650);
      if (sessions.isEmpty) {
        return null;
      }
      return sessions.first.endedAt;
    }
    final db = await database;
    final rows = await db.query(
      'game_sessions',
      columns: ['ended_at'],
      where: 'user_id = ? AND game_id = ?',
      whereArgs: [userId, gameId],
      orderBy: 'ended_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return DateTime.parse(rows.first['ended_at'] as String);
  }

  Future<List<Map<String, dynamic>>> _readPrefsRows(String key) async {
    final prefs = await _preferences;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((row) => row.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  Future<void> _writePrefsRows(String key, List<Map<String, dynamic>> rows) async {
    final prefs = await _preferences;
    await prefs.setString(key, jsonEncode(rows));
  }

  void _upsertRow(
    List<Map<String, dynamic>> rows,
    Map<String, dynamic> nextRow, {
    List<String> idFields = const ['id'],
  }) {
    final index = rows.indexWhere(
      (row) => idFields.every((field) => row[field] == nextRow[field]),
    );
    if (index == -1) {
      rows.add(nextRow);
      return;
    }
    rows[index] = nextRow;
  }
}
