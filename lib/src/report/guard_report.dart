import '../cli/options.dart';
import '../core/result.dart';
import '../coverage/file_coverage_record.dart';

/// Machine-readable report emitted at the end of a guard run.
class GuardReport {
  /// Creates a [GuardReport].
  const GuardReport({
    required this.success,
    required this.exitCode,
    required this.steps,
    required this.coverage,
  });

  /// Builds a stable JSON report from the final run result and CLI options.
  factory GuardReport.fromRunResult(
    CiGuardOptions options,
    GuardRunResult result,
  ) {
    return GuardReport(
      success: result.success,
      exitCode: result.exitCode,
      steps: <StepReport>[
        _buildStepReport(
          stepName: 'format',
          actualStepName: 'format',
          skipped: options.skipFormat,
          completedSteps: result.completedSteps,
        ),
        _buildStepReport(
          stepName: 'analyze',
          actualStepName: 'analyze',
          skipped: options.skipAnalyze,
          completedSteps: result.completedSteps,
        ),
        _buildStepReport(
          stepName: 'test',
          actualStepName: 'tests',
          skipped: options.skipTests,
          completedSteps: result.completedSteps,
        ),
      ],
      coverage: CoverageReport.fromRunResult(options, result),
    );
  }

  /// Whether the overall run passed.
  final bool success;

  /// The final exit code returned to the calling process.
  final int exitCode;

  /// The standard format/analyze/test step reports in order.
  final List<StepReport> steps;

  /// The final coverage report.
  final CoverageReport coverage;

  /// Converts this report to a JSON-serializable map.
  Map<String, Object> toJson() {
    return <String, Object>{
      'success': success,
      'exit_code': exitCode,
      'steps': steps.map((StepReport step) => step.toJson()).toList(),
      'coverage': coverage.toJson(),
    };
  }

  static StepReport _buildStepReport({
    required String stepName,
    required String actualStepName,
    required bool skipped,
    required List<StepResult> completedSteps,
  }) {
    StepResult? step;
    for (final completedStep in completedSteps) {
      if (completedStep.name == actualStepName) {
        step = completedStep;
        break;
      }
    }

    if (step != null) {
      return StepReport(
        name: stepName,
        success: step.success,
        durationMs: step.durationMs,
      );
    }

    return StepReport(name: stepName, success: skipped, durationMs: 0);
  }
}

/// Machine-readable step execution result.
class StepReport {
  /// Creates a [StepReport].
  const StepReport({
    required this.name,
    required this.success,
    required this.durationMs,
  });

  /// Stable step name used in JSON output.
  final String name;

  /// Whether the step completed successfully.
  final bool success;

  /// The step execution time in milliseconds.
  final int durationMs;

  /// Converts this report to a JSON-serializable map.
  Map<String, Object> toJson() {
    return <String, Object>{
      'name': name,
      'success': success,
      'duration_ms': durationMs,
    };
  }
}

/// Machine-readable coverage result.
class CoverageReport {
  /// Creates a [CoverageReport].
  const CoverageReport({
    required this.globalPercentage,
    required this.linesFound,
    required this.linesHit,
    required this.minimumRequired,
    required this.excludedFilesCount,
    required this.lowFiles,
  });

  /// Builds a stable coverage payload, even when coverage could not be read.
  factory CoverageReport.fromRunResult(
    CiGuardOptions options,
    GuardRunResult result,
  ) {
    final coverageResult = result.coverageResult;
    if (coverageResult == null) {
      return CoverageReport(
        globalPercentage: 0.0,
        linesFound: 0,
        linesHit: 0,
        minimumRequired: options.minCoverage,
        excludedFilesCount: 0,
        lowFiles: const <LowFileReport>[],
      );
    }

    return CoverageReport(
      globalPercentage: coverageResult.summary.percentage,
      linesFound: coverageResult.summary.linesFound,
      linesHit: coverageResult.summary.linesHit,
      minimumRequired: coverageResult.minimumCoverage,
      excludedFilesCount: coverageResult.excludedFilesCount,
      lowFiles: coverageResult.lowCoverageFiles
          .map(LowFileReport.fromRecord)
          .toList(growable: false),
    );
  }

  /// Overall project coverage percentage.
  final double globalPercentage;

  /// Total executable lines found.
  final int linesFound;

  /// Total executable lines hit by tests.
  final int linesHit;

  /// Minimum required global coverage percentage.
  final int minimumRequired;

  /// Number of files excluded from coverage.
  final int excludedFilesCount;

  /// Low-coverage files reported by the guard.
  final List<LowFileReport> lowFiles;

  /// Converts this report to a JSON-serializable map.
  Map<String, Object> toJson() {
    return <String, Object>{
      'global_percentage': globalPercentage,
      'lines_found': linesFound,
      'lines_hit': linesHit,
      'minimum_required': minimumRequired,
      'excluded_files_count': excludedFilesCount,
      'low_files': lowFiles.map((LowFileReport file) => file.toJson()).toList(),
    };
  }
}

/// Machine-readable representation of a low-coverage file.
class LowFileReport {
  /// Creates a [LowFileReport].
  const LowFileReport({required this.path, required this.percentage});

  /// Creates a [LowFileReport] from an existing coverage record.
  factory LowFileReport.fromRecord(FileCoverageRecord record) {
    return LowFileReport(path: record.path, percentage: record.percentage);
  }

  /// Relative file path reported by LCOV.
  final String path;

  /// Per-file coverage percentage.
  final double percentage;

  /// Converts this report to a JSON-serializable map.
  Map<String, Object> toJson() {
    return <String, Object>{'path': path, 'percentage': percentage};
  }
}
