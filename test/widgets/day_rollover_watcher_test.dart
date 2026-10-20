import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/widgets/day_rollover_watcher.dart';

void main() {
  testWidgets('an app left open past midnight starts the new day',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var clockNow = DateTime(2026, 10, 16, 23, 59);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appClockProvider.overrideWithValue(() => clockNow),
    ]);
    addTearDown(container.dispose);
    await container.read(appStateProvider.notifier).completeQuest('walk');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const DayRolloverWatcher(child: SizedBox()),
    ));
    await tester.pump(const Duration(minutes: 1));
    expect(container.read(appStateProvider).questsDoneToday, contains('walk'));

    clockNow = DateTime(2026, 10, 17, 0, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(container.read(appStateProvider).questsDoneToday, isEmpty);

    await tester.pumpWidget(const SizedBox());
  });
}
