/// Partial configuration loaded from `flutter_ci_guard.yaml`.
///
/// All fields are nullable so partial config files can merge cleanly with
/// defaults and explicit CLI overrides.
class GuardConfig {
  /// Creates a [GuardConfig].
  const GuardConfig({
    this.formatStepEnabled,
    this.analyzeStepEnabled,
    this.testStepEnabled,
    this.minCoverage,
    this.coveragePath,
    this.coverageExclude,
    this.perFileMinCoverage,
    this.showTopLowFiles,
  });

  /// Whether the format step should run.
  final bool? formatStepEnabled;

  /// Whether the analyze step should run.
  final bool? analyzeStepEnabled;

  /// Whether the test step should run.
  final bool? testStepEnabled;

  /// Minimum acceptable coverage percentage.
  final int? minCoverage;

  /// Path to the LCOV report.
  final String? coveragePath;

  /// Glob patterns for files excluded from coverage calculation.
  final List<String>? coverageExclude;

  /// Minimum acceptable per-file coverage percentage.
  final int? perFileMinCoverage;

  /// Maximum number of low-coverage files to show.
  final int? showTopLowFiles;
}
