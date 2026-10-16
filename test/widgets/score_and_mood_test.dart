import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/widgets/quick_mood_log.dart';
import 'package:zeno/widgets/score_breakdown_sheet.dart';

Future<ProviderContainer> _pump(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  ));
  return container;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('tapping a mood logs it and moves the score', (tester) async {
    final container = await _pump(tester, const QuickMoodLog());
    expect(container.read(cogniPulseProvider), 60);

    await tester.tap(find.text('🌟'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(appStateProvider).todaysMood, 90);
    expect(container.read(cogniPulseProvider), 78);
    expect(find.text('Thriving'), findsOneWidget);

    // Let flutter_animate's entrance timers finish before teardown.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the breakdown explains the score and the missing signal',
      (tester) async {
    final container = await _pump(tester, const ScoreBreakdownSheet());
    await container.read(appStateProvider.notifier).logMood(90);
    await tester.pump();

    expect(find.text('Why is my score 78?'), findsOneWidget);
    expect(find.text('Mood check-in'), findsOneWidget);
    expect(find.text('Phone usage'), findsOneWidget);
    expect(find.text('Not measured in this build'), findsOneWidget);
    expect(find.textContaining('(90 × 0.15 + 60 × 0.10) ÷ 0.25 = 78'), findsOneWidget);
  });
}
