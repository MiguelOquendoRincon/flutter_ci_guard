import '../cli/options.dart';
import '../output/console.dart';
import '../process/command_executor.dart';
import '../process/flutter_commands.dart';
import 'exit_codes.dart';
import 'result.dart';

class CiGuard {
  CiGuard({required CommandExecutor executor, required Console console})
    : _executor = executor,
      _console = console;

  final CommandExecutor _executor;
  final Console _console;

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

    _console.info('\nAll enabled quality gates passed.');

    return GuardRunResult(
      success: true,
      exitCode: ExitCodes.success,
      completedSteps: completedSteps,
    );
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
