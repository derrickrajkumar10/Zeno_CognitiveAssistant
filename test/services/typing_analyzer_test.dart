import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/services/typing_analyzer.dart';

const _target = 'Small steps every day can carry you a very long way.';

/// Evenly spaced keystrokes, one per character, [msPerKey] apart.
List<DateTime> _keys(int count, int msPerKey) {
  final start = DateTime(2026, 10, 16, 9);
  return List.generate(count, (i) => start.add(Duration(milliseconds: i * msPerKey)));
}

void main() {
  test('nothing typed gives no result', () {
    expect(
      TypingAnalyzer.analyze(target: _target, typed: '', keystrokes: const [], backspaces: 0),
      isNull,
    );
  });

  test('fast, exact typing with no corrections scores 100', () {
    // 52 chars at 150 ms/key = 7.65 s -> about 82 wpm, capped at full speed.
    final result = TypingAnalyzer.analyze(
      target: _target,
      typed: _target,
      keystrokes: _keys(_target.length, 150),
      backspaces: 0,
    )!;
    expect(result.accuracy, 1);
    expect(result.wpm, closeTo(81.6, 0.5));
    expect(result.score, 100);
    expect(result.stress, 0);
  });

  test('slow typing with corrections and long pauses scores lower', () {
    final keys = _keys(_target.length, 600);
    final result = TypingAnalyzer.analyze(
      target: _target,
      typed: _target,
      keystrokes: keys,
      backspaces: 8,
    )!;
    expect(result.wpm, lessThan(25));
    expect(result.correctionRate, greaterThan(0.5));
    expect(result.score, lessThan(75));
  });

  test('pauses over 1.5 s are counted', () {
    final start = DateTime(2026, 10, 16, 9);
    final keys = [
      start,
      start.add(const Duration(milliseconds: 200)),
      start.add(const Duration(milliseconds: 2200)),
      start.add(const Duration(milliseconds: 2400)),
      start.add(const Duration(milliseconds: 2600)),
    ];
    final result = TypingAnalyzer.analyze(
      target: 'abcde',
      typed: 'abcde',
      keystrokes: keys,
      backspaces: 0,
    )!;
    expect(result.pauseRatio, 0.25);
  });

  test('typing far more than the sentence keeps the score in range', () {
    final typed = _target * 5;
    final result = TypingAnalyzer.analyze(
      target: _target,
      typed: typed,
      keystrokes: _keys(typed.length, 100),
      backspaces: 0,
    )!;
    expect(result.accuracy, inInclusiveRange(0, 1));
    expect(result.score, inInclusiveRange(0, 100));
  });

  test('a typo lowers accuracy by edit distance', () {
    final typed = _target.replaceFirst('carry', 'cary');
    final result = TypingAnalyzer.analyze(
      target: _target,
      typed: typed,
      keystrokes: _keys(typed.length, 150),
      backspaces: 0,
    )!;
    expect(result.accuracy, closeTo(1 - 1 / _target.length, 1e-9));
  });
}
