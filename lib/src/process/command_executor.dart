import 'dart:io';

import '../core/result.dart';

/// Abstract interface for running an external process as a quality-gate step.
///
/// Provides a seam for testing: production code uses [ProcessCommandExecutor],
/// while tests can supply a mock implementation without spawning real processes.
abstract class CommandExecutor {
  /// Runs the command identified by [executable] and [arguments].
  ///
  /// The [stepName] is a short, human-readable label used for logging
  /// (e.g., `'format'`, `'analyze'`).
  ///
  /// Returns a [StepResult] containing the exit code, stdout, and stderr
  /// of the completed process.
  Future<StepResult> run({
    required String stepName,
    required String executable,
    required List<String> arguments,
  });
}

/// A [CommandExecutor] that spawns real OS processes using [Process.run].
///
/// This is the default implementation used in production. It captures both
/// stdout and stderr and maps the process exit code to a [StepResult].
class ProcessCommandExecutor implements CommandExecutor {
  /// Creates a const [ProcessCommandExecutor].
  const ProcessCommandExecutor();

  @override
  Future<StepResult> run({
    required String stepName,
    required String executable,
    required List<String> arguments,
  }) async {
    final ProcessResult result = await Process.run(executable, arguments);

    final String stdoutText = (result.stdout ?? '').toString();
    final String stderrText = (result.stderr ?? '').toString();
    final int exitCode = result.exitCode;

    return StepResult(
      name: stepName,
      success: exitCode == 0,
      exitCode: exitCode,
      stdout: stdoutText,
      stderr: stderrText,
    );
  }
}
