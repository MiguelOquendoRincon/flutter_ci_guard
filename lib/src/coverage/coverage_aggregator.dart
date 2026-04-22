import 'coverage_summary.dart';
import 'file_coverage_record.dart';

/// Aggregates file-level coverage records into a single summary.
class CoverageAggregator {
  /// Creates a const [CoverageAggregator].
  const CoverageAggregator();

  /// Returns the total coverage summary across [records].
  CoverageSummary aggregate(Iterable<FileCoverageRecord> records) {
    int linesFound = 0;
    int linesHit = 0;

    for (final FileCoverageRecord record in records) {
      linesFound += record.linesFound;
      linesHit += record.linesHit;
    }

    return CoverageSummary(linesFound: linesFound, linesHit: linesHit);
  }
}
