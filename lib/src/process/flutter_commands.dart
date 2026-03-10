/// Describes a shell command to be executed as a quality-gate step.
///
/// Instances are created by the factory methods on [FlutterCommands] and
/// consumed by [CiGuard] via a [CommandExecutor].
class FlutterCommand {
  /// Creates a [FlutterCommand].
  const FlutterCommand({
    required this.stepName,
    required this.executable,
    required this.arguments,
  });

  /// Short, human-readable name used in log output (e.g., `'format'`).
  final String stepName;

  /// The executable to invoke (e.g., `'dart'`, `'flutter'`).
  final String executable;

  /// The list of arguments to pass to [executable].
  final List<String> arguments;
}

/// Factory methods for the standard Flutter quality-gate commands.
///
/// Each method returns a pre-configured [FlutterCommand] ready to be
/// passed to a [CommandExecutor].
abstract final class FlutterCommands {
  /// Returns the command that checks and enforces code formatting.
  ///
  /// Equivalent to running:
  /// ```
  /// dart format --set-exit-if-changed .
  /// ```
  /// The `--set-exit-if-changed` flag causes the process to exit with a
  /// non-zero code if any file needs reformatting, which fails the gate.
  static FlutterCommand format() {
    return const FlutterCommand(
      stepName: 'format',
      executable: 'dart',
      arguments: <String>['format', '--set-exit-if-changed', '.'],
    );
  }

  /// Returns the command that runs static analysis on the project.
  ///
  /// Equivalent to running:
  /// ```
  /// flutter analyze
  /// ```
  static FlutterCommand analyze() {
    return const FlutterCommand(
      stepName: 'analyze',
      executable: 'flutter',
      arguments: <String>['analyze'],
    );
  }

  /// Returns the command that runs the test suite and generates an LCOV report.
  ///
  /// Equivalent to running:
  /// ```
  /// flutter test --coverage
  /// ```
  /// The `--coverage` flag causes Flutter to write coverage data to
  /// `coverage/lcov.info`, which is later read by [CoverageChecker].
  static FlutterCommand testWithCoverage() {
    return const FlutterCommand(
      stepName: 'tests',
      executable: 'flutter',
      arguments: <String>['test', '--coverage'],
    );
  }
}
