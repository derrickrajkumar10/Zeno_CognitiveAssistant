import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/insights/insights_screen.dart';
import 'package:zeno/services/wellness_repository.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Friday.
  final now = DateTime(2026, 10, 16, 18);

  Future<void> pumpInsights(WidgetTester tester, List<SignalReading> signals) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      WellnessRepository.signalsKey:
          jsonEncode(signals.map((s) => s.toMap()).toList()),
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appStateProvider.overrideWith((ref) => AppStateNotifier(prefs, clock: () => now)),
      ],
      child: const MaterialApp(home: Scaffold(body: InsightsScreen())),
    ));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200,
        scrollable: find.byType(Scrollable).first);
  }

  testWidgets('a fresh install shows empty states instead of fake numbers',
      (tester) async {
    await pumpInsights(tester, const []);

    expect(find.text('No check-ins yet'), findsOneWidget);
    expect(find.text('--'), findsNWidgets(3));
    await scrollTo(tester, find.text('Mochi will spot patterns after a few check-ins.'));
  });

  testWidgets('a week of check-ins shows real weekdays, patterns and history',
      (tester) async {
    await pumpInsights(tester, [
      SignalReading(type: SignalType.selfReport, score: 40, at: DateTime(2026, 10, 12, 9)),
      SignalReading(type: SignalType.selfReport, score: 45, at: DateTime(2026, 10, 13, 9)),
      SignalReading(type: SignalType.selfReport, score: 80, at: DateTime(2026, 10, 15, 9)),
      SignalReading(type: SignalType.selfReport, score: 85, at: DateTime(2026, 10, 16, 9)),
      SignalReading(
        type: SignalType.game,
        score: 70,
        at: DateTime(2026, 10, 16, 12),
        stress: 30,
        note: 'bubble_drift',
      ),
    ]);

    // The chart ends on today (Friday) and starts on last Saturday.
    expect(find.text('Sat'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('No check-ins yet'), findsNothing);
    expect(find.text('5 of 7'), findsNothing);
    expect(find.text('4 of 7'), findsOneWidget);

    await scrollTo(tester, find.text('Trending up'));
    await scrollTo(tester, find.text('Bubble Drift'));
    await scrollTo(tester, find.text('Mood check-in').last);
  });
}
