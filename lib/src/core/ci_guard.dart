import 'dart:io';

import '../cli/options.dart';
import '../coverage/coverage_checker.dart';
import '../coverage/lcov_parser.dart';
import '../output/console.dart';
import '../process/command_executor.dart';
import '../process/flutter_commands.dart';
import 'exit_codes.dart';
import 'result.dart';

class CiGuard {
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

  GuardRunResult _checkCoverage(
    CiGuardOptions options,
    List<StepResult> completedSteps,
  ) {
    _console.section('Checking coverage');
    _console.info('Reading coverage from ${options.coveragePath}');
    _console.info('Minimum required coverage: ${options.minCoverage}%');

    try {
      final CoverageCheckResult result = _coverageChecker.check(
        coveragePath: options.coveragePath,
        minimumCoverage: options.minCoverage,
      );

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
    } on LcovParseException catch (error) {
      _console.error(error.toString());

      return GuardRunResult(
        success: false,
        exitCode: ExitCodes.coverageParseError,
        completedSteps: completedSteps,
      );
    }
  }

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
