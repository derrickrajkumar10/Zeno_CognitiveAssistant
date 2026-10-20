import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zeno/screens/onboarding/baseline_page.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpPage(WidgetTester tester, ValueChanged<List<int>> onDone) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: BaselinePage(onComplete: onDone)));
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> answer(WidgetTester tester, int question, int value) async {
    final chip = find.byKey(ValueKey('baseline-$question-$value'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
  }

  testWidgets('continue stays disabled until all five questions are answered',
      (tester) async {
    List<int>? result;
    await pumpPage(tester, (answers) => result = answers);

    for (var q = 0; q < 4; q++) {
      await answer(tester, q, 3);
    }
    final button = find.widgetWithText(ElevatedButton, 'Continue >');
    await tester.ensureVisible(button);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    await answer(tester, 4, 3);
    await tester.ensureVisible(button);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    expect(result, isNull);
  });

  testWidgets('answers are reported in question order, last tap wins',
      (tester) async {
    List<int>? result;
    await pumpPage(tester, (answers) => result = answers);

    await answer(tester, 0, 1);
    await answer(tester, 0, 5);
    await answer(tester, 1, 4);
    await answer(tester, 2, 3);
    await answer(tester, 3, 4);
    await answer(tester, 4, 2);
    final button = find.widgetWithText(ElevatedButton, 'Continue >');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(result, [5, 4, 3, 4, 2]);
  });
}
