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

  /// Returns low-coverage files from [records] after sorting and limiting.
  ///
  /// Files with zero executable lines are ignored to avoid noisy output and
  /// division-by-zero concerns. When [minimumCoverage] is `null`, files are
  /// not threshold-filtered. When [topCount] is provided, only the first
  /// [topCount] files from the sorted result are returned.
  List<FileCoverageRecord> selectLowCoverageFiles(
    Iterable<FileCoverageRecord> records, {
    int? minimumCoverage,
    int? topCount,
  }) {
    if (minimumCoverage == null && topCount == null) {
      return const <FileCoverageRecord>[];
    }

    final List<FileCoverageRecord> lowCoverageFiles =
        records
            .where((FileCoverageRecord record) => record.linesFound > 0)
            .where(
              (FileCoverageRecord record) =>
                  minimumCoverage == null ||
                  record.percentage < minimumCoverage,
            )
            .toList(growable: false)
          ..sort((FileCoverageRecord left, FileCoverageRecord right) {
            final int percentageComparison = left.percentage.compareTo(
              right.percentage,
            );
            if (percentageComparison != 0) {
              return percentageComparison;
            }

            return left.path.compareTo(right.path);
          });

    if (topCount == null || lowCoverageFiles.length <= topCount) {
      return lowCoverageFiles;
    }

    return lowCoverageFiles.take(topCount).toList(growable: false);
  }
}
