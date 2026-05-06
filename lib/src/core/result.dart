import '../coverage/coverage_checker.dart';

/// The result of running a single quality-gate step (e.g., format, analyze).
///
/// Produced by [CommandExecutor.run] and stored in [GuardRunResult.completedSteps].
class StepResult {
  /// Creates a [StepResult].
  const StepResult({
    required this.name,
    required this.success,
    required this.exitCode,
    this.durationMs = 0,
    this.stdout = '',
    this.stderr = '',
  });

  /// The human-readable name of the step (e.g., `'format'`, `'analyze'`).
  final String name;

  /// Whether the step completed with exit code 0.
  final bool success;

  /// The raw process exit code returned by the underlying command.
  final int exitCode;

  /// The step execution time in milliseconds.
  final int durationMs;

  /// The standard output captured from the process, if any.
  final String stdout;

  /// The standard error captured from the process, if any.
  final String stderr;
}

/// The aggregated result of a full [CiGuard.run] execution.
///
/// Contains the overall success status, the final exit code to propagate
/// to the CI environment, the list of steps that were completed, and
/// the step that caused a failure (if any).
class GuardRunResult {
  /// Creates a [GuardRunResult].
  const GuardRunResult({
    required this.success,
    required this.exitCode,
    required this.completedSteps,
    this.coverageResult,
    this.failedStep,
  });

  /// Whether all enabled quality gates passed.
  final bool success;

  /// The exit code to return to the shell / CI environment.
  ///
  /// See [ExitCodes] for the full list of possible values.
  final int exitCode;

  /// All steps that were executed, in order, regardless of outcome.
  final List<StepResult> completedSteps;

  /// The final coverage evaluation result, when available.
  final CoverageCheckResult? coverageResult;

  /// The first step that failed, or `null` if all steps succeeded.
  final StepResult? failedStep;
}
