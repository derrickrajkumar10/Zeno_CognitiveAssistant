import 'dart:convert';

import 'package:flutter/material.dart';

/// Raw on-device interaction captured during a game session.
class GameTouchEventRecord {
  final String id;
  final String sessionId;
  final String userId;
  final String gameId;
  final int reactionTimeMs;
  final double tapPressure;
  final Offset tapPosition;
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic> gameContext;

  const GameTouchEventRecord({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.gameId,
    required this.reactionTimeMs,
    required this.tapPressure,
    required this.tapPosition,
    required this.eventType,
    required this.timestamp,
    this.gameContext = const {},
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'user_id': userId,
        'game_id': gameId,
        'reaction_time_ms': reactionTimeMs,
        'tap_pressure': tapPressure,
        'tap_x': tapPosition.dx,
        'tap_y': tapPosition.dy,
        'event_type': eventType,
        'timestamp': timestamp.toIso8601String(),
        'game_context_json': jsonEncode(gameContext),
      };

  factory GameTouchEventRecord.fromMap(Map<String, dynamic> map) {
    final contextJson = map['game_context_json'] as String? ?? '{}';
    final decoded = jsonDecode(contextJson);
    return GameTouchEventRecord(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      userId: map['user_id'] as String,
      gameId: map['game_id'] as String,
      reactionTimeMs: (map['reaction_time_ms'] as num?)?.toInt() ?? 0,
      tapPressure: (map['tap_pressure'] as num?)?.toDouble() ?? 0.0,
      tapPosition: Offset(
        (map['tap_x'] as num?)?.toDouble() ?? 0.0,
        (map['tap_y'] as num?)?.toDouble() ?? 0.0,
      ),
      eventType: map['event_type'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      gameContext: decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map),
    );
  }
}
