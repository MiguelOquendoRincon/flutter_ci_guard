import 'dart:io';

import '../core/exit_codes.dart';
import 'coverage_summary.dart';
import 'lcov_parser.dart';

class CoverageCheckResult {
  const CoverageCheckResult({
    required this.success,
    required this.exitCode,
    required this.summary,
    required this.minimumCoverage,
  });

  final bool success;
  final int exitCode;
  final CoverageSummary summary;
  final int minimumCoverage;
}

class CoverageChecker {
  CoverageChecker({required LcovParser parser}) : _parser = parser;

  final LcovParser _parser;

  CoverageCheckResult check({
    required String coveragePath,
    required int minimumCoverage,
  }) {
    final File file = File(coveragePath);

    if (!file.existsSync()) {
      throw const FileSystemException('Coverage file not found.');
    }

    final String content = file.readAsStringSync();
    final CoverageSummary summary = _parser.parse(content);

    final bool passed = summary.percentage >= minimumCoverage;

    return CoverageCheckResult(
      success: passed,
      exitCode: passed ? ExitCodes.success : ExitCodes.coverageBelowThreshold,
      summary: summary,
      minimumCoverage: minimumCoverage,
    );
  }
}
