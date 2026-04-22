import 'dart:io';

import '../cli/options.dart';
import '../coverage/coverage_checker.dart';
import '../coverage/lcov_parser.dart';
import '../output/console.dart';
import '../process/command_executor.dart';
import '../process/flutter_commands.dart';
import 'exit_codes.dart';
import 'result.dart';

/// Orchestrates the Flutter CI quality gates in sequence.
///
/// [CiGuard] is the central component of `flutter_ci_guard`. It runs each
/// enabled quality gate in order — format → analyze → tests → coverage — and
/// stops immediately when the first gate fails (fail-fast strategy).
///
/// Each gate produces a [StepResult] that is accumulated in the final
/// [GuardRunResult]. This allows callers to inspect exactly how far the
/// execution got before a failure occurred.
///
/// Example:
/// ```dart
/// final guard = CiGuard(
///   executor: ProcessCommandExecutor(),
///   console: Console(),
/// );
/// final result = await guard.run(options);
/// exit(result.exitCode);
/// ```
class CiGuard {
  /// Creates a [CiGuard] with the provided [executor] and [console].
  ///
  /// If [coverageChecker] is omitted, a default [CoverageChecker] backed by
  /// a [LcovParser] is used. Pass a custom instance to facilitate testing.
  CiGuard({
    required CommandExecutor executor,
    required Console console,
    CoverageChecker? coverageChecker,
  }) : _executor = executor,
       _console = console,
       _coverageChecker =
           coverageChecker ?? CoverageChecker(parser: const LcovParser());

  final CommandExecutor _executor;
  final Console _console;
  final CoverageChecker _coverageChecker;

  /// Runs all enabled quality gates and returns an aggregated [GuardRunResult].
  ///
  /// Gates are executed in the following order:
  /// 1. **Format** – skipped if [CiGuardOptions.skipFormat] is `true`.
  /// 2. **Analyze** – skipped if [CiGuardOptions.skipAnalyze] is `true`.
  /// 3. **Tests** – skipped if [CiGuardOptions.skipTests] is `true`.
  /// 4. **Coverage** – always evaluated using the LCOV file.
  ///
  /// The method returns as soon as any gate fails, without executing
  /// subsequent gates.
  ///
  /// Returns a [GuardRunResult] with [GuardRunResult.success] set to `true`
  /// only if all enabled gates pass.
  Future<GuardRunResult> run(CiGuardOptions options) async {
    final List<StepResult> completedSteps = <StepResult>[];

    if (!options.skipFormat) {
      final StepResult result = await _runCommand(FlutterCommands.format());
      completedSteps.add(result);

      if (!result.success) {
        return GuardRunResult(
          success: false,
          exitCode: ExitCodes.commandFailed,
          completedSteps: completedSteps,
          failedStep: result,
        );
      }
    }

    if (!options.skipAnalyze) {
      final StepResult result = await _runCommand(FlutterCommands.analyze());
      completedSteps.add(result);

      if (!result.success) {
        return GuardRunResult(
          success: false,
          exitCode: ExitCodes.commandFailed,
          completedSteps: completedSteps,
          failedStep: result,
        );
      }
    }

    if (!options.skipTests) {
      final StepResult result = await _runCommand(
        FlutterCommands.testWithCoverage(),
      );
      completedSteps.add(result);

      if (!result.success) {
        return GuardRunResult(
          success: false,
          exitCode: ExitCodes.commandFailed,
          completedSteps: completedSteps,
          failedStep: result,
        );
      }
    }

    final GuardRunResult coverageResult = _checkCoverage(
      options,
      completedSteps,
    );
    if (!coverageResult.success) {
      return coverageResult;
    }

    _console.info('\nAll enabled quality gates passed.');
    return coverageResult;
  }

  /// Reads and validates the LCOV coverage report.
  ///
  /// Handles [FileSystemException] (file not found) and [LcovParseException]
  /// (malformed file) gracefully, printing a descriptive error message and
  /// returning a failed [GuardRunResult] with the appropriate exit code.
  GuardRunResult _checkCoverage(
    CiGuardOptions options,
    List<StepResult> completedSteps,
  ) {
    _console.section('Checking coverage');
    _console.info('Reading coverage from ${options.coveragePath}');
    _console.info('Minimum required coverage: ${options.minCoverage}%');
    if (options.coverageExclude.isNotEmpty) {
      _console.info(
        'Coverage exclusions: ${options.coverageExclude.join(', ')}',
      );
    }

    try {
      final CoverageCheckResult result = _coverageChecker.check(
        coveragePath: options.coveragePath,
        minimumCoverage: options.minCoverage,
        excludePatterns: options.coverageExclude,
      );

      if (result.excludedFilesCount > 0) {
        _console.info(
          'Excluded ${result.excludedFilesCount} file(s) from coverage',
        );
      }

      final String formattedCoverage = result.summary.percentage
          .toStringAsFixed(2);

      _console.info(
        'Coverage: $formattedCoverage% '
        '(${result.summary.linesHit}/${result.summary.linesFound} lines)',
      );

      if (!result.success) {
        _console.error(
          '✗ coverage check failed: minimum is ${result.minimumCoverage}%',
        );

        return GuardRunResult(
          success: false,
          exitCode: result.exitCode,
          completedSteps: completedSteps,
        );
      }

      _console.info('✓ coverage check passed');

      return GuardRunResult(
        success: true,
        exitCode: ExitCodes.success,
        completedSteps: completedSteps,
      );
    } on FileSystemException {
      _console.error('Coverage file not found at "${options.coveragePath}".');

      return GuardRunResult(
        success: false,
        exitCode: ExitCodes.coverageFileNotFound,
        completedSteps: completedSteps,
      );
    } on CoverageCheckException catch (error) {
      _console.error(error.toString());

      return GuardRunResult(
        success: false,
        exitCode: ExitCodes.coverageParseError,
        completedSteps: completedSteps,
      );
    } on LcovParseException catch (error) {
      _console.error(error.toString());

      return GuardRunResult(
        success: false,
        exitCode: ExitCodes.coverageParseError,
        completedSteps: completedSteps,
      );
    }
  }

  /// Executes a [FlutterCommand] via the injected [CommandExecutor] and
  /// prints progress to the [Console].
  ///
  /// Logs stdout/stderr output from the process and emits a pass/fail
  /// indicator to the console.
  Future<StepResult> _runCommand(FlutterCommand command) async {
    _console.section('Running ${command.stepName}');
    _console.info('${command.executable} ${command.arguments.join(' ')}');

    final StepResult result = await _executor.run(
      stepName: command.stepName,
      executable: command.executable,
      arguments: command.arguments,
    );

    if (result.stdout.trim().isNotEmpty) {
      _console.info(result.stdout.trim());
    }

    if (result.stderr.trim().isNotEmpty) {
      _console.error(result.stderr.trim());
    }

    if (result.success) {
      _console.info('✓ ${command.stepName} passed');
    } else {
      _console.error(
        '✗ ${command.stepName} failed with exit code ${result.exitCode}',
      );
    }

    return result;
  }
}
