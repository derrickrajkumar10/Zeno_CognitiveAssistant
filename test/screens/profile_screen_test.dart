import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/profile/profile_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ));
    await tester.pump(const Duration(seconds: 2));
    return container;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200,
        scrollable: find.byType(Scrollable).first);
  }

  testWidgets('locked badges show how close the user is', (tester) async {
    final container = await pumpProfile(tester);
    await container.read(appStateProvider.notifier).recordBreathingSession();
    await tester.pump();

    await scrollTo(tester, find.text('Deep Breather'));
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('0/50'), findsOneWidget); // Mochi's Favourite

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('the weekly letter is written from this week, not a template',
      (tester) async {
    final container = await pumpProfile(tester);
    await container.read(appStateProvider.notifier).updateUserName('Sam');
    await container.read(appStateProvider.notifier).logMood(90);
    await tester.pump();

    await scrollTo(tester, find.text("Mochi's Weekly Letter"));
    await tester.tap(find.text("Mochi's Weekly Letter"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Dear Sam,'), findsOneWidget);
    expect(find.textContaining('1 of the last 7 days'), findsOneWidget);
    expect(find.textContaining('Alex'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
