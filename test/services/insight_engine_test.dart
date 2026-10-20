import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/models/signal_reading.dart';
import 'package:zeno/services/insight_engine.dart';

void main() {
  // Friday.
  final now = DateTime(2026, 10, 16, 18);

  SignalReading mood(int score, DateTime at) =>
      SignalReading(type: SignalType.selfReport, score: score, at: at);
  SignalReading typing(int score, DateTime at) =>
      SignalReading(type: SignalType.typing, score: score, at: at);

  Insight? find(List<Insight> insights, InsightKind kind) =>
      insights.where((i) => i.kind == kind).firstOrNull;

  test('no check-ins means no insights', () {
    expect(InsightEngine.build(const [], null, now), isEmpty);
  });

  test('a single check-in only reports consistency', () {
    final insights = InsightEngine.build([mood(70, DateTime(2026, 10, 16, 9))], null, now);
    expect(insights.map((i) => i.kind), [InsightKind.consistency]);
    expect(insights.single.title, 'Checked in 1 of the last 7 days');
  });

  test('a rising week is reported as a trend, with the best day named', () {
    // Day scores without a baseline: 0.6 × mood + 24 → 48, 51, 72, 75.
    final insights = InsightEngine.build([
      mood(40, DateTime(2026, 10, 12, 9)),
      mood(45, DateTime(2026, 10, 13, 9)),
      mood(80, DateTime(2026, 10, 15, 9)),
      mood(85, DateTime(2026, 10, 16, 9)),
    ], null, now);

    final trend = find(insights, InsightKind.trend)!;
    expect(trend.title, 'Trending up');
    expect(trend.description, contains('24 points'));
    final best = find(insights, InsightKind.bestDay)!;
    expect(best.title, 'Best day: Friday');
    expect(best.description, contains('75'));
  });

  test('a flat week is reported as steady', () {
    final insights = InsightEngine.build([
      mood(60, DateTime(2026, 10, 13, 9)),
      mood(62, DateTime(2026, 10, 14, 9)),
      mood(61, DateTime(2026, 10, 15, 9)),
    ], null, now);
    expect(find(insights, InsightKind.trend)!.title, 'Holding steady');
  });

  test('morning check-ins scoring higher than evening ones are called out', () {
    final insights = InsightEngine.build([
      typing(80, DateTime(2026, 10, 14, 9)),
      typing(50, DateTime(2026, 10, 14, 20)),
      typing(82, DateTime(2026, 10, 15, 8)),
      typing(48, DateTime(2026, 10, 15, 21)),
    ], null, now);
    final timeOfDay = find(insights, InsightKind.timeOfDay)!;
    expect(timeOfDay.title, 'Mornings feel lighter');
    expect(timeOfDay.description, contains('81'));
    expect(timeOfDay.description, contains('49'));
  });

  test('time of day needs two check-ins on each side', () {
    final insights = InsightEngine.build([
      typing(80, DateTime(2026, 10, 14, 9)),
      typing(50, DateTime(2026, 10, 14, 20)),
    ], null, now);
    expect(find(insights, InsightKind.timeOfDay), isNull);
  });

  test('typing that looks far more stressed than the mood rating is flagged', () {
    final insights = InsightEngine.build([
      typing(40, DateTime(2026, 10, 16, 10)),
      mood(90, DateTime(2026, 10, 16, 11)),
    ], null, now);
    final gap = find(insights, InsightKind.typingVsMood)!;
    expect(gap.title, 'Your typing looks more tense than you feel');
    expect(gap.description, contains('90'));
    expect(gap.description, contains('40'));
  });

  test('a small typing and mood gap is not flagged', () {
    final insights = InsightEngine.build([
      typing(70, DateTime(2026, 10, 16, 10)),
      mood(80, DateTime(2026, 10, 16, 11)),
    ], null, now);
    expect(find(insights, InsightKind.typingVsMood), isNull);
  });

  test('check-ins older than seven days are ignored', () {
    final insights = InsightEngine.build([
      typing(40, DateTime(2026, 10, 2, 10)),
      mood(90, DateTime(2026, 10, 2, 11)),
    ], null, now);
    expect(insights, isEmpty);
  });
}
