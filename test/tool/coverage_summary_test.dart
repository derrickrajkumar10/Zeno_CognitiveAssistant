import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_summary.dart';

void main() {
  test('sums lines found and hit across files', () {
    const lcov = '''
SF:lib/a.dart
DA:1,1
LF:10
LH:8
end_of_record
SF:lib/b.dart
LF:30
LH:12
end_of_record
''';
    final summary = parseLcov(lcov);

    expect(summary.files.map((f) => f.path), ['lib/a.dart', 'lib/b.dart']);
    expect(summary.linesFound, 40);
    expect(summary.linesHit, 20);
    expect(summary.percent, 50);
    expect(summary.files.first.percent, 80);
  });

  test('an empty report is 0% rather than a division by zero', () {
    final summary = parseLcov('');
    expect(summary.files, isEmpty);
    expect(summary.percent, 0);
  });

  test('the headline line reads naturally', () {
    final summary = parseLcov('SF:lib/a.dart\nLF:3\nLH:2\nend_of_record\n');
    expect(summary.headline, 'Line coverage: 66.7% (2/3 lines, 1 files)');
  });
}
