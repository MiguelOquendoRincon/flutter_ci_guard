import 'coverage_summary.dart';

/// Exception thrown when the LCOV file content cannot be parsed.
///
/// This is a typed exception that allows callers to distinguish LCOV
/// parse errors from other I/O or runtime failures.
class LcovParseException implements Exception {
  /// Creates an [LcovParseException] with the provided [message].
  const LcovParseException(this.message);

  /// A human-readable description of the parse error.
  final String message;

  @override
  String toString() {
    return 'LcovParseException: $message';
  }
}

/// Parses the content of an LCOV coverage report file.
///
/// LCOV is the standard format produced by `flutter test --coverage`.
/// This parser reads only the `DA:` (data line) entries, which describe
/// individual line coverage, and aggregates them into a [CoverageSummary].
///
/// Other entries such as `SF:`, `FN:`, `FNDA:`, `BRDA:`, `LF:`, `LH:`,
/// and `end_of_record` are intentionally ignored.
///
/// Example usage:
/// ```dart
/// const parser = LcovParser();
/// final summary = parser.parse(File('coverage/lcov.info').readAsStringSync());
/// print('${summary.percentage.toStringAsFixed(2)}%');
/// ```
class LcovParser {
  /// Creates a const [LcovParser].
  const LcovParser();

  /// Parses the raw LCOV [content] and returns a [CoverageSummary].
  ///
  /// Iterates over all `DA:<lineNumber>,<executionCount>` entries in the
  /// content. Each `DA:` line represents a single executable source line:
  /// - [linesFound] is incremented for every `DA:` entry.
  /// - [linesHit] is incremented when the execution count is greater than 0.
  ///
  /// If [content] contains no `DA:` entries (e.g., empty file), a summary
  /// with `linesFound == 0` and `linesHit == 0` is returned.
  ///
  /// Throws a [LcovParseException] if any `DA:` entry is malformed,
  /// contains a non-integer value, or has a negative number.
  CoverageSummary parse(String content) {
    final List<String> lines = content.split('\n');

    int linesFound = 0;
    int linesHit = 0;

    for (final String rawLine in lines) {
      final String line = rawLine.trim();

      if (line.isEmpty || !line.startsWith('DA:')) {
        continue;
      }

      final _LineCoverageEntry entry = _parseDaLine(line);
      linesFound++;

      if (entry.executionCount > 0) {
        linesHit++;
      }
    }

    return CoverageSummary(linesFound: linesFound, linesHit: linesHit);
  }

  /// Parses a single `DA:<lineNumber>,<executionCount>` entry.
  ///
  /// Throws [LcovParseException] if:
  /// - The entry does not contain a comma separator.
  /// - [lineNumber] is not a valid non-negative integer.
  /// - [executionCount] is not a valid non-negative integer.
  _LineCoverageEntry _parseDaLine(String line) {
    final String payload = line.substring(3);
    final List<String> parts = payload.split(',');

    if (parts.length < 2) {
      throw LcovParseException('Invalid DA entry: "$line"');
    }

    final int? lineNumber = int.tryParse(parts[0].trim());
    final int? executionCount = int.tryParse(parts[1].trim());

    if (lineNumber == null || lineNumber < 0) {
      throw LcovParseException('Invalid line number in DA entry: "$line"');
    }

    if (executionCount == null || executionCount < 0) {
      throw LcovParseException('Invalid execution count in DA entry: "$line"');
    }

    return _LineCoverageEntry(
      lineNumber: lineNumber,
      executionCount: executionCount,
    );
  }
}

/// Internal data class representing a single parsed `DA:` line.
class _LineCoverageEntry {
  const _LineCoverageEntry({
    required this.lineNumber,
    required this.executionCount,
  });

  /// The 1-based source line number.
  final int lineNumber;

  /// The number of times this line was executed during the test run.
  final int executionCount;
}
