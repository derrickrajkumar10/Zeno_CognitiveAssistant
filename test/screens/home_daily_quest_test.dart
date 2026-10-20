import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/main.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/quests/quests_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Daily Quest on Home opens the Quests tab', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ZenoApp(),
    ));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));

    final button = find.text('Daily Quest');
    await tester.ensureVisible(button);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(QuestsScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
