import 'coverage_summary.dart';

/// Line-coverage data for a single source file from an LCOV report.
class FileCoverageRecord {
  /// Creates a [FileCoverageRecord].
  const FileCoverageRecord({
    required this.path,
    required this.linesFound,
    required this.linesHit,
  });

  /// Source file path from the LCOV `SF:` entry.
  final String path;

  /// Number of executable lines found for this file.
  final int linesFound;

  /// Number of executable lines hit for this file.
  final int linesHit;

  /// Aggregated coverage summary for this file.
  CoverageSummary get summary {
    return CoverageSummary(linesFound: linesFound, linesHit: linesHit);
  }
}
