import 'dart:io';

import '../core/exit_codes.dart';
import 'coverage_aggregator.dart';
import 'coverage_excluder.dart';
import 'file_coverage_record.dart';
import 'coverage_summary.dart';
import 'lcov_parser.dart';

/// Exception thrown when coverage cannot be evaluated after exclusions.
class CoverageCheckException implements Exception {
  /// Creates a [CoverageCheckException].
  const CoverageCheckException(this.message);

  /// A human-readable description of the error.
  final String message;

  @override
  String toString() {
    return 'CoverageCheckException: $message';
  }
}

/// The result of a coverage check against a minimum threshold.
///
/// Returned by [CoverageChecker.check].
class CoverageCheckResult {
  /// Creates a [CoverageCheckResult].
  const CoverageCheckResult({
    required this.success,
    required this.exitCode,
    required this.summary,
    required this.minimumCoverage,
    required this.excludedFilesCount,
    required this.includedFilesCount,
  });

  /// Whether the actual coverage met or exceeded [minimumCoverage].
  final bool success;

  /// The process exit code to propagate to the CI environment.
  ///
  /// [ExitCodes.success] when [success] is `true`;
  /// [ExitCodes.coverageBelowThreshold] when [success] is `false`.
  final int exitCode;

  /// The parsed coverage statistics from the LCOV report.
  final CoverageSummary summary;

  /// The minimum coverage percentage that was required.
  final int minimumCoverage;

  /// Number of files excluded before coverage aggregation.
  final int excludedFilesCount;

  /// Number of files included in the final coverage calculation.
  final int includedFilesCount;
}

/// Reads an LCOV file and checks whether coverage meets a minimum threshold.
///
/// The checker delegates LCOV parsing to the injected [LcovParser], keeping
/// file I/O and parsing as separate concerns that can each be tested
/// independently.
///
/// Example:
/// ```dart
/// final checker = CoverageChecker(parser: const LcovParser());
/// final result = checker.check(
///   coveragePath: 'coverage/lcov.info',
///   minimumCoverage: 80,
/// );
/// if (!result.success) {
///   print('Coverage too low: ${result.summary.percentage}%');
/// }
/// ```
class CoverageChecker {
  /// Creates a [CoverageChecker] using the provided [parser].
  CoverageChecker({
    required LcovParser parser,
    CoverageExcluder excluder = const CoverageExcluder(),
    CoverageAggregator aggregator = const CoverageAggregator(),
  }) : _parser = parser,
       _excluder = excluder,
       _aggregator = aggregator;

  final LcovParser _parser;
  final CoverageExcluder _excluder;
  final CoverageAggregator _aggregator;

  /// Reads the LCOV file at [coveragePath] and evaluates the coverage
  /// against [minimumCoverage].
  ///
  /// Returns a [CoverageCheckResult] describing whether the threshold was met.
  ///
  /// Throws a [FileSystemException] if the file at [coveragePath] does not
  /// exist or cannot be read.
  ///
  /// Throws a [LcovParseException] if the file content is malformed and
  /// cannot be parsed.
  CoverageCheckResult check({
    required String coveragePath,
    required int minimumCoverage,
    List<String> excludePatterns = const <String>[],
  }) {
    final File file = File(coveragePath);

    if (!file.existsSync()) {
      throw const FileSystemException('Coverage file not found.');
    }

    final String content = file.readAsStringSync();
    final List<FileCoverageRecord> records = _parser.parseRecords(content);
    final List<FileCoverageRecord> includedRecords = records
        .where(
          (FileCoverageRecord record) =>
              !_excluder.isExcluded(record.path, excludePatterns),
        )
        .toList(growable: false);

    if (records.isNotEmpty && includedRecords.isEmpty) {
      throw const CoverageCheckException(
        'All coverage files were excluded from calculation.',
      );
    }

    final CoverageSummary summary = _aggregator.aggregate(includedRecords);

    final bool passed = summary.percentage >= minimumCoverage;

    return CoverageCheckResult(
      success: passed,
      exitCode: passed ? ExitCodes.success : ExitCodes.coverageBelowThreshold,
      summary: summary,
      minimumCoverage: minimumCoverage,
      excludedFilesCount: records.length - includedRecords.length,
      includedFilesCount: includedRecords.length,
    );
  }
}
