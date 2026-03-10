class StepResult {
  const StepResult({
    required this.name,
    required this.success,
    required this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final String name;
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;
}

class GuardRunResult {
  const GuardRunResult({
    required this.success,
    required this.exitCode,
    required this.completedSteps,
    this.failedStep,
  });

  final bool success;
  final int exitCode;
  final List<StepResult> completedSteps;
  final StepResult? failedStep;
}
