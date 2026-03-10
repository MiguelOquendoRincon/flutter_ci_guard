import 'coverage_summary.dart';

class LcovParseException implements Exception {
  const LcovParseException(this.message);

  final String message;

  @override
  String toString() {
    return 'LcovParseException: $message';
  }
}

class LcovParser {
  const LcovParser();

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

class _LineCoverageEntry {
  const _LineCoverageEntry({
    required this.lineNumber,
    required this.executionCount,
  });

  final int lineNumber;
  final int executionCount;
}
