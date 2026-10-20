import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/games/game_wrapper.dart';
import 'package:zeno/screens/games/post_game_screen.dart';

import '../services/game_test_helpers.dart';

Future<ProviderContainer> _pumpGame(WidgetTester tester) async {
  await resetGameStore();
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: GameWrapper(
        gameId: 'bubble_drift',
        gameTitle: 'Bubble Drift',
        xpReward: 15,
        gameBuilder: (game) => Center(
          child: ElevatedButton(
            onPressed: () {
              game.recordTouch(eventType: 'tap_hit', reactionTimeMs: 300);
              game.endGame(score: 80, levelReached: 3);
            },
            child: const Text('Finish'),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _flushMochiTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('finishing a game shows results, awards XP and records a game '
      'signal', (tester) async {
    final container = await _pumpGame(tester);

    await tester.tap(find.text('Finish'));
    await _settle(tester);

    expect(find.byType(PostGameScreen), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);

    final state = container.read(appStateProvider);
    expect(state.xpEvents.where((e) => e.source == 'game').single.amount, 15);
    // First session ever: nothing to compare against, so a neutral 60.
    final game = state.signals.where((s) => s.type == SignalType.game).single;
    expect(game.score, 60);
    expect(game.note, 'bubble_drift');

    await _flushMochiTimers(tester);
  });

  testWidgets('leaving a game early shows results with no XP and no signal',
      (tester) async {
    final container = await _pumpGame(tester);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await _settle(tester);

    expect(find.byType(PostGameScreen), findsOneWidget);
    expect(find.text('+0'), findsOneWidget);
    final state = container.read(appStateProvider);
    expect(state.xpEvents.where((e) => e.source == 'game'), isEmpty);
    expect(state.signals.where((s) => s.type == SignalType.game), isEmpty);

    await _flushMochiTimers(tester);
  });
}
