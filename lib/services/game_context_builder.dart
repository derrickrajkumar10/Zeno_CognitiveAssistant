import 'package:zeno/models/game_session.dart';
import 'package:zeno/services/game_repository.dart';

/// Builds a game behavior summary that gets appended to Mochi's prompt context.
class GameContextBuilder {
  final GameRepository _repo;

  GameContextBuilder({GameRepository? repo}) : _repo = repo ?? GameRepository();

  Future<String> buildGameContext({String userId = 'alex'}) async {
    final recentSessions = await _repo.getRecentSessions(userId, days: 7);
    final twoWeekSessions = await _repo.getRecentSessions(userId, days: 14);
    final flaggedPatterns = _detectPatterns(recentSessions, twoWeekSessions);

    return '''

Game behavior signals (last 7 days):
- Reaction time trend: ${_reactionTrend(recentSessions)}
- Memory scores: ${_memoryTrend(recentSessions)}
- Session completion rate: ${(_completionRate(recentSessions) * 100).round()}%
- Most played game: ${_mostPlayedGame(recentSessions)}
- Flagged patterns: ${flaggedPatterns.isEmpty ? 'none' : flaggedPatterns.join(', ')}

Use these signals to inform Mochi's emotional intuition. Never mention
"reaction time", "data", "signals", or "tracking" directly. Speak only
through Mochi's personality and emotional observations.
''';
  }

  String _reactionTrend(List<GameSession> sessions) {
    if (sessions.length < 2) {
      return 'stable (+0ms vs baseline)';
    }
    final split = sessions.length < 4 ? 1 : sessions.length ~/ 2;
    final recent = sessions.take(split).toList(growable: false);
    final older = sessions.skip(split).toList(growable: false);
    if (older.isEmpty) {
      return 'stable (+0ms vs baseline)';
    }

    final recentAvg = recent.fold<double>(0, (sum, session) => sum + session.avgReactionMs) /
        recent.length;
    final olderAvg = older.fold<double>(0, (sum, session) => sum + session.avgReactionMs) /
        older.length;
    final deltaMs = (recentAvg - olderAvg).round();

    if (deltaMs > 25) {
      return 'trending up (+${deltaMs}ms vs baseline)';
    }
    if (deltaMs < -25) {
      return 'trending down (${deltaMs}ms vs baseline)';
    }
    final signedDelta = deltaMs >= 0 ? '+$deltaMs' : '$deltaMs';
    return 'stable (${signedDelta}ms vs baseline)';
  }

  String _memoryTrend(List<GameSession> sessions) {
    final memorySessions = sessions
        .where((session) => session.gameId == 'memory_garden')
        .toList(growable: false);
    if (memorySessions.length < 2) {
      return 'stable';
    }
    final latestAccuracy = 1 - memorySessions.first.errorRate;
    final oldestAccuracy = 1 - memorySessions.last.errorRate;
    final delta = latestAccuracy - oldestAccuracy;
    if (delta > 0.08) {
      return 'improving';
    }
    if (delta < -0.08) {
      return 'declining';
    }
    return 'stable';
  }

  double _completionRate(List<GameSession> sessions) {
    if (sessions.isEmpty) {
      return 0;
    }
    final completed = sessions.where((session) => !session.dropOffEarly).length;
    return completed / sessions.length;
  }

  String _mostPlayedGame(List<GameSession> sessions) {
    if (sessions.isEmpty) {
      return 'none';
    }
    final counts = <String, int>{};
    for (final session in sessions) {
      counts[session.gameId] = (counts[session.gameId] ?? 0) + 1;
    }
    final sortedEntries = counts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return sortedEntries.first.key;
  }

  List<String> _detectPatterns(
    List<GameSession> recentSessions,
    List<GameSession> twoWeekSessions,
  ) {
    final patterns = <String>[];

    if (_hasReactionElevatedThreeDays(recentSessions)) {
      patterns.add('reaction_time_elevated_3_days');
    }

    final currentWeek = recentSessions;
    final previousWeek = twoWeekSessions
        .where((session) => session.startedAt.isBefore(
              DateTime.now().subtract(const Duration(days: 7)),
            ))
        .toList(growable: false);
    if (previousWeek.isNotEmpty &&
        _completionRate(currentWeek) < _completionRate(previousWeek)) {
      patterns.add('drop_off_rate_increasing');
    }

    if (_hasMemoryDecline(recentSessions)) {
      patterns.add('memory_declining');
    }

    if (recentSessions.isEmpty ||
        DateTime.now().difference(recentSessions.first.endedAt).inHours >= 48) {
      patterns.add('no_games_played_48h');
    }

    return patterns;
  }

  bool _hasReactionElevatedThreeDays(List<GameSession> sessions) {
    final dailyAverageDelta = <String, List<double>>{};
    for (final session in sessions) {
      final dayKey = session.startedAt.toIso8601String().split('T').first;
      dailyAverageDelta.putIfAbsent(dayKey, () => <double>[]).add(session.reactionDelta);
    }
    final orderedDays = dailyAverageDelta.keys.toList()..sort();
    if (orderedDays.length < 3) {
      return false;
    }
    int streak = 0;
    for (final day in orderedDays.reversed) {
      final deltas = dailyAverageDelta[day]!;
      final average = deltas.reduce((a, b) => a + b) / deltas.length;
      if (average > 1.0) {
        streak++;
        if (streak >= 3) {
          return true;
        }
      } else {
        streak = 0;
      }
    }
    return false;
  }

  bool _hasMemoryDecline(List<GameSession> sessions) {
    final memorySessions = sessions
        .where((session) => session.gameId == 'memory_garden')
        .toList(growable: false);
    if (memorySessions.length < 5) {
      return false;
    }
    final latestFive = memorySessions.take(5).toList(growable: false);
    final recentAccuracy = latestFive
            .take(3)
            .map((session) => 1 - session.errorRate)
            .reduce((a, b) => a + b) /
        3;
    final olderAccuracy = latestFive
            .skip(3)
            .map((session) => 1 - session.errorRate)
            .reduce((a, b) => a + b) /
        2;
    return recentAccuracy < olderAccuracy - 0.08;
  }
}
