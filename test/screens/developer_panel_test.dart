import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/screens/developer/developer_panel.dart';
import 'package:zeno/screens/profile/profile_screen.dart';
import 'package:zeno/services/ollama_settings.dart';
import 'package:zeno/widgets/mochi_widget.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpPanel(WidgetTester tester) async {
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
      child: const MaterialApp(home: DeveloperPanel()),
    ));
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200,
        scrollable: find.byType(Scrollable).first);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('long-pressing Mochi on Profile opens the developer tools',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ));
    await tester.pump(const Duration(seconds: 2));

    await tester.longPress(find.byType(MochiWidget));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Developer tools'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the slider overrides the score and "Use real score" clears it',
      (tester) async {
    final container = await pumpPanel(tester);
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(90);
    await tester.pump();

    expect(container.read(cogniPulseProvider), 90);
    expect(find.textContaining('Thriving'), findsOneWidget);

    await tester.tap(find.text('Use real score'));
    await tester.pump();
    expect(container.read(appStateProvider).scoreOverride, isNull);
    expect(container.read(cogniPulseProvider), 60);
    await unmount(tester);
  });

  testWidgets('seeding shows up in the stored data viewer', (tester) async {
    final container = await pumpPanel(tester);
    await scrollTo(tester, find.text('Seed demo week'));
    await tester.tap(find.text('Seed demo week'));
    await tester.pump();
    expect(container.read(appStateProvider).signals, isNotEmpty);

    await scrollTo(tester, find.text('Show stored data'));
    await tester.tap(find.text('Show stored data'));
    await tester.pump();
    expect(find.textContaining('"note": "demo"'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the Ollama host is normalised, saved and tested', (tester) async {
    final container = await pumpPanel(tester);
    final field = find.byKey(const ValueKey('ollama-host'));
    await scrollTo(tester, field);
    await tester.enterText(field, '192.168.1.5:11434/');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(container.read(ollamaHostProvider), 'http://192.168.1.5:11434');

    // flutter_test answers every real HTTP request with 400, so no server.
    await tester.tap(find.text('Test connection'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('MOCK'), findsOneWidget);
    expect(container.read(appStateProvider).isOllamaLive, isFalse);
    await unmount(tester);
  });
}
