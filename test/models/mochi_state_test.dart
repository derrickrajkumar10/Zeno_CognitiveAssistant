import 'package:flutter_test/flutter_test.dart';
import 'package:zeno/models/mochi_state.dart';

void main() {
  test('Mochi breathes faster when thriving and slower when struggling', () {
    expect(MochiMoodState.thriving.breathPeriod, const Duration(milliseconds: 1800));
    expect(MochiMoodState.balanced.breathPeriod, const Duration(milliseconds: 2500));
    expect(MochiMoodState.drifting.breathPeriod, const Duration(milliseconds: 3400));
    expect(MochiMoodState.struggling.breathPeriod, const Duration(milliseconds: 4500));
  });
}
