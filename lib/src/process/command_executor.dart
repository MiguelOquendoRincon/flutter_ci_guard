import 'dart:io';

import '../core/result.dart';

abstract class CommandExecutor {
  Future<StepResult> run({
    required String stepName,
    required String executable,
    required List<String> arguments,
  });
}

class ProcessCommandExecutor implements CommandExecutor {
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
