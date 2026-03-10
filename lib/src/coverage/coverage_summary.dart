/// Aggregated line-coverage statistics for a project.
///
/// Produced by [LcovParser] from an LCOV report, and consumed by
/// [CoverageChecker] to decide whether a coverage threshold is met.
class CoverageSummary {
  /// Creates a [CoverageSummary] with the given line counts.
  ///
  /// Both [linesFound] and [linesHit] must be non-negative. [linesHit] must
  /// not exceed [linesFound].
  const CoverageSummary({required this.linesFound, required this.linesHit});

  /// Total number of executable lines found in the report.
  final int linesFound;

  /// Number of executable lines that were executed at least once.
  final int linesHit;

  /// The coverage percentage, in the range `[0.0, 100.0]`.
  ///
  /// Returns `0.0` when [linesFound] is zero to avoid division by zero.
  ///
  /// Example:
  /// ```dart
  /// const summary = CoverageSummary(linesFound: 10, linesHit: 9);
  /// print(summary.percentage); // 90.0
  /// ```
  double get percentage {
    if (linesFound == 0) {
      return 0.0;
    }

    return (linesHit / linesFound) * 100;
  }
}
