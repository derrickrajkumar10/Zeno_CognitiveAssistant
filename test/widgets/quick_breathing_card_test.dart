import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/widgets/quick_breathing_card.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pump(WidgetTester tester, VoidCallback onComplete) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: QuickBreathingCard(
            rounds: 2,
            phaseDuration: const Duration(seconds: 1),
            onComplete: onComplete,
          ),
        ),
      ),
    ));
    return container;
  }

  testWidgets('finishing every round completes the session once', (tester) async {
    var completions = 0;
    final container = await pump(tester, () => completions++);

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Round 1 of 2'), findsOneWidget);
    expect(find.text('Inhale'), findsOneWidget);

    // 2 rounds × 4 phases × 1 s.
    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(completions, 1);
    expect(container.read(appStateProvider).counters['breathing_sessions'], 1);
    expect(find.textContaining('Nice'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('stopping early never completes', (tester) async {
    var completions = 0;
    final container = await pump(tester, () => completions++);

    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.close_rounded));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(completions, 0);
    expect(container.read(appStateProvider).counters['breathing_sessions'], isNull);
    expect(find.text('Start'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
