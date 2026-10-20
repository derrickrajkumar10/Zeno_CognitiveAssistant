import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/widgets/typing_check_in.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: TypingCheckIn(sentenceIndex: 0)),
        ),
      ),
    ));
    return container;
  }

  testWidgets('typing the sentence records a typing reading', (tester) async {
    final container = await pump(tester);
    final sentence = TypingCheckIn.sentences[0];

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    for (var i = 1; i <= sentence.length; i++) {
      await tester.enterText(find.byType(TextField), sentence.substring(0, i));
    }
    await tester.pump();
    await tester.tap(find.text('Finish check-in'));
    await tester.pump(const Duration(milliseconds: 600));

    final reading = container.read(appStateProvider).signals.single;
    expect(reading.type, SignalType.typing);
    expect(find.textContaining('wpm'), findsWidgets);
    expect(find.text('Try another sentence'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('pasting the sentence is rejected', (tester) async {
    final container = await pump(tester);
    await tester.enterText(find.byType(TextField), TypingCheckIn.sentences[0]);
    await tester.pump();

    expect(find.textContaining('type it out'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(container.read(appStateProvider).signals, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
