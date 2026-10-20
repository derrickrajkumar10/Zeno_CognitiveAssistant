// Prints line coverage from `flutter test --coverage`.
//
//   dart run tool/coverage_summary.dart [path/to/lcov.info] [--min=60] [--files]
//
// --min fails (exit code 1) when total coverage is below the given percent.
// --files also lists every file, least covered first.
import 'dart:io';

class FileCoverage {
  final String path;
  final int linesFound;
  final int linesHit;

  const FileCoverage(this.path, this.linesFound, this.linesHit);

  double get percent => linesFound == 0 ? 0 : 100 * linesHit / linesFound;
}

class CoverageSummary {
  final List<FileCoverage> files;

  const CoverageSummary(this.files);

  int get linesFound => files.fold(0, (sum, f) => sum + f.linesFound);
  int get linesHit => files.fold(0, (sum, f) => sum + f.linesHit);
  double get percent => linesFound == 0 ? 0 : 100 * linesHit / linesFound;

  String get headline => 'Line coverage: ${percent.toStringAsFixed(1)}% '
      '($linesHit/$linesFound lines, ${files.length} files)';
}

CoverageSummary parseLcov(String lcov) {
  final files = <FileCoverage>[];
  String? path;
  var found = 0;
  var hit = 0;
  for (final line in lcov.split('\n').map((l) => l.trim())) {
    if (line.startsWith('SF:')) {
      path = line.substring(3);
      found = 0;
      hit = 0;
    } else if (line.startsWith('LF:')) {
      found = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && path != null) {
      files.add(FileCoverage(path, found, hit));
      path = null;
    }
  }
  return CoverageSummary(files);
}

void main(List<String> args) {
  final path = args.firstWhere((a) => !a.startsWith('--'),
      orElse: () => 'coverage/lcov.info');
  final minArg = args.where((a) => a.startsWith('--min=')).firstOrNull;
  final min = minArg == null ? null : double.parse(minArg.substring(6));

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('No coverage report at $path. Run: flutter test --coverage');
    exit(2);
  }
  final summary = parseLcov(file.readAsStringSync());

  if (args.contains('--files')) {
    final sorted = [...summary.files]
      ..sort((a, b) => a.percent.compareTo(b.percent));
    for (final f in sorted) {
      stdout.writeln('${f.percent.toStringAsFixed(1).padLeft(5)}%  '
          '${'${f.linesHit}/${f.linesFound}'.padLeft(9)}  ${f.path}');
    }
  }
  stdout.writeln(summary.headline);

  if (min != null && summary.percent < min) {
    stderr.writeln('Coverage is below the ${min.toStringAsFixed(0)}% floor.');
    exit(1);
  }
}
