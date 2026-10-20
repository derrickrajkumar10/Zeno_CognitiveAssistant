import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/services/demo_seeder.dart';

void main() {
  final now = DateTime(2026, 10, 16, 18);

  test('the demo week covers the six days before today and leaves today empty',
      () {
    final week = DemoSeeder.week(now);
    final days = week.signals.map((s) => DateTime(s.at.year, s.at.month, s.at.day)).toSet();
    expect(days, {
      for (var i = 1; i <= 6; i++) DateTime(2026, 10, 16 - i),
    });
    expect(week.signals.where((s) => s.type == SignalType.selfReport).length, 6);
  });

  test('every demo row is tagged so it can be found and removed', () {
    final week = DemoSeeder.week(now);
    expect(week.signals.every(DemoSeeder.isDemoSignal), isTrue);
    expect(week.xpEvents, isNotEmpty);
    expect(week.xpEvents.every(DemoSeeder.isDemoXp), isTrue);
  });

  test('scores stay in range and the same seed gives the same week', () {
    final a = DemoSeeder.week(now);
    final b = DemoSeeder.week(now);
    expect(a.signals.every((s) => s.score >= 0 && s.score <= 100), isTrue);
    expect(a.signals.map((s) => s.toMap()).toList(), b.signals.map((s) => s.toMap()).toList());
    expect(DemoSeeder.week(now, seed: 1).signals.map((s) => s.score).toList(),
        isNot(a.signals.map((s) => s.score).toList()));
  });
}
