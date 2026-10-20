import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/games/bubble_drift_game.dart';
import 'package:zeno/screens/games/dream_sort_game.dart';
import 'package:zeno/screens/games/focus_flicker_game.dart';
import 'package:zeno/screens/games/memory_garden_game.dart';
import 'package:zeno/screens/games/mochi_says_game.dart';
import 'package:zeno/screens/games/playroom_screen.dart';
import 'package:zeno/screens/games/post_game_screen.dart';
import 'package:zeno/screens/games/puzzle_world_game.dart';
import 'package:zeno/screens/games/slice_calm_game.dart';
import 'package:zeno/screens/games/wave_sync_game.dart';

import '../services/game_test_helpers.dart';

const _games = <String, Widget>{
  'Bubble Drift': BubbleDriftGame(),
  'Mochi Says': MochiSaysGame(),
  'Wave Sync': WaveSyncGame(),
  'Memory Garden': MemoryGardenGame(),
  'Slice & Calm': SliceCalmGame(),
  'Focus Flicker': FocusFlickerGame(),
  'Dream Sort': DreamSortGame(),
  "Mochi's Puzzle World": PuzzleWorldGame(),
};

Future<void> _pumpInApp(WidgetTester tester, Widget home) async {
  // A portrait phone (360 x 780 logical pixels), not the 800 x 600 default.
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await resetGameStore();
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: home),
  ));
}

/// Runs [body] while ignoring RenderFlex overflow reports.
///
/// Widget tests draw every glyph as a full-em box, about twice as wide as
/// Nunito, so a one-line HUD that fits on a 360 dp phone overflows here.
/// Every other error still fails the test.
Future<void> _ignoringTextOverflow(Future<void> Function() body) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
      return;
    }
    original?.call(details);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = original;
  }
}

Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the Playroom lists all eight games', (tester) async {
    await _ignoringTextOverflow(() async {
      await _pumpInApp(tester, const Scaffold(body: PlayroomScreen()));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      final seen = <String>{};
      for (var i = 0; i < 10 && seen.length < _games.length; i++) {
        seen.addAll(
            _games.keys.where((t) => find.text(t).evaluate().isNotEmpty));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(seen, _games.keys.toSet());
      await _flushTimers(tester);
    });
  });

  for (final MapEntry(key: title, value: game) in _games.entries) {
    testWidgets(
        '$title opens, runs for five seconds, takes taps and exits to '
        'results', (tester) async {
      await _ignoringTextOverflow(() async {
        await _pumpInApp(tester, game);

        final size = tester.view.physicalSize / tester.view.devicePixelRatio;
        for (var i = 0; i < 25; i++) {
          await tester.pump(const Duration(milliseconds: 200));
          if (i.isOdd) {
            await tester.tapAt(
              Offset(size.width * (0.2 + 0.06 * (i % 10)), size.height * 0.55),
            );
          }
        }
        expect(find.text(title), findsWidgets);

        // Leaving early still ends on the results screen, never stuck.
        if (find.byType(PostGameScreen).evaluate().isEmpty) {
          await tester.tap(find.byIcon(Icons.close_rounded));
        }
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(PostGameScreen), findsOneWidget);

        await _flushTimers(tester);
      });
    });
  }
}
