import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/quests/quests_screen.dart';
import 'package:zeno/widgets/quick_breathing_card.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the Box Breathing quest opens a breathing session and completes '
      'only after it finishes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: QuestsScreen())),
    ));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Box Breathing'));
    // One frame starts the sheet's slide-in, the next lets it finish.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(QuickBreathingCard), findsOneWidget);
    expect(container.read(appStateProvider).questsDoneToday, isNot(contains('breathing')));

    await tester.tap(find.text('Start'));
    // 4 rounds × 4 phases × 4 s.
    for (var i = 0; i < 17; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(QuickBreathingCard), findsNothing);
    expect(container.read(appStateProvider).questsDoneToday, contains('breathing'));
    expect(container.read(appStateProvider).counters['breathing_sessions'], 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
