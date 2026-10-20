import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/main.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/router/app_router.dart';
import 'package:zeno/screens/onboarding/onboarding_flow.dart';
import 'package:zeno/screens/profile/profile_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
  }

  Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
    tallView(tester);
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

  Future<void> tapSetting(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(find.text(label), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('only settings that exist are listed', (tester) async {
    await pumpProfile(tester);
    await tester.scrollUntilVisible(find.text('About ZENO'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Edit name'), findsOneWidget);
    expect(find.text('Reset all data'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('edit name saves the trimmed name', (tester) async {
    final container = await pumpProfile(tester);
    await tapSetting(tester, 'Edit name');
    await tester.enterText(find.byType(TextField), '  Sam  ');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(appStateProvider).user.name, 'Sam');
    await unmount(tester);
  });

  testWidgets('a blank name cannot be saved', (tester) async {
    final container = await pumpProfile(tester);
    final before = container.read(appStateProvider).user.name;
    await tapSetting(tester, 'Edit name');
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    final save = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(save.onPressed, isNull);
    expect(container.read(appStateProvider).user.name, before);
    await unmount(tester);
  });

  testWidgets('About says what is and is not measured', (tester) async {
    await pumpProfile(tester);
    await tapSetting(tester, 'About ZENO');
    expect(find.text('Phone usage'), findsOneWidget);
    expect(find.textContaining('Not measured in this build'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('not a medical'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.textContaining('not a medical'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('reset all data asks first, then starts onboarding again',
      (tester) async {
    tallView(tester);
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ZenoApp(),
    ));
    await tester.pump(const Duration(seconds: 6));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));
    await container.read(appStateProvider.notifier).logMood(90);
    container.read(routerProvider).go('/profile');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tapSetting(tester, 'Reset all data');
    expect(find.text('Reset everything?'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(container.read(appStateProvider).signals, isEmpty);
    expect(prefs.getBool('onboarding_complete'), isNull);
    await unmount(tester);
  });
}
