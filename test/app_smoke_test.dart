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
}
