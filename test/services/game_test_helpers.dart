import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/game_session.dart';
import 'package:zeno/services/game_repository.dart';

/// Gives each test an empty game store.
///
/// sqflite has no plugin under `flutter test`, so [GameRepository] falls
/// back to SharedPreferences, which these mock values back.
Future<void> resetGameStore() async {
  SharedPreferences.setMockInitialValues({});
  await GameRepository().clearAll();
}

GameSession session({
  required String id,
  String gameId = 'bubble_drift',
  required DateTime startedAt,
  double avgReactionMs = 400,
  double avgPressure = 0.5,
  double errorRate = 0.1,
  double hesitationIndex = 0.1,
  bool dropOffEarly = false,
}) {
  return GameSession(
    id: id,
    userId: 'alex',
    gameId: gameId,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 2)),
    sessionLengthSec: 120,
    avgReactionMs: avgReactionMs,
    avgPressure: avgPressure,
    pressureVariance: 0.01,
    errorRate: errorRate,
    hesitationIndex: hesitationIndex,
    levelReached: 2,
    dropOffEarly: dropOffEarly,
  );
}
