/// Exit codes returned by `flutter_ci_guard` to the calling shell or CI system.
///
/// These codes follow the UNIX convention where `0` means success and any
/// non-zero value indicates a specific failure mode. CI systems (GitHub
/// Actions, GitLab CI, etc.) inspect the exit code to decide whether to
/// mark a pipeline step as passed or failed.
abstract final class ExitCodes {
  /// Command succeeded; all quality gates passed.
  static const int success = 0;

  /// Invalid CLI arguments were provided.
  ///
  /// Follows the BSD convention (`EX_USAGE = 64`) for incorrect usage.
  static const int invalidArguments = 64;

  /// A quality-gate command (format, analyze, or tests) returned a non-zero
  /// exit code.
  static const int commandFailed = 1;

  /// The LCOV coverage percentage is below the configured minimum threshold.
  static const int coverageBelowThreshold = 2;

  /// The coverage report file was not found at the specified path.
  ///
  /// This typically means `flutter test --coverage` was not run beforehand,
  /// or `--coverage-path` points to the wrong location.
  static const int coverageFileNotFound = 3;

  /// The coverage report file exists but its content is not valid LCOV.
  static const int coverageParseError = 4;
}
