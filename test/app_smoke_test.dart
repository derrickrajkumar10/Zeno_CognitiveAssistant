import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/main.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/home/home_screen.dart';
import 'package:zeno/screens/onboarding/onboarding_flow.dart';
import 'package:zeno/screens/splash/splash_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('first launch: splash, onboarding, skip, then home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ZenoApp(),
    ));

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(OnboardingFlow), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(prefs.getBool('onboarding_complete'), isTrue);

    // Mochi's idle loops (blink, look, ear twitch) use delayed futures;
    // unmount and let them expire so no timers outlive the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('onboarding baseline answers become the starting score',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ZenoApp(),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));

    Future<void> tapVisible(Finder finder) async {
      await tester.ensureVisible(finder.hitTestable());
      await tester.tap(finder.hitTestable());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    await tapVisible(find.text("Let's go >")); // Welcome
    await tapVisible(find.text('Continue >')); // Name
    await tapVisible(find.text('Continue >')); // Companion
    expect(find.text('How have you been lately?'), findsOneWidget);

    const answers = [5, 4, 3, 4, 2]; // 100, 75, 50, 75, 25 → 65
    for (var q = 0; q < answers.length; q++) {
      await tapVisible(find.byKey(ValueKey('baseline-$q-${answers[q]}')));
    }
    await tapVisible(find.text('Continue >')); // Baseline

    expect(find.text('Privacy first.\nAlways.'), findsOneWidget);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(OnboardingFlow)));
    expect(container.read(appStateProvider).baseline?.answers, answers);
    expect(container.read(cogniPulseProvider), 65);
    expect(prefs.getString('zeno.baseline'), isNotNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
