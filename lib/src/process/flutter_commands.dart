class FlutterCommand {
  const FlutterCommand({
    required this.stepName,
    required this.executable,
    required this.arguments,
  });

  final String stepName;
  final String executable;
  final List<String> arguments;
}

abstract final class FlutterCommands {
  static FlutterCommand format() {
    return const FlutterCommand(
      stepName: 'format',
      executable: 'flutter',
      arguments: <String>['format', '--set-exit-if-changed', '.'],
    );
  }

  static FlutterCommand analyze() {
    return const FlutterCommand(
      stepName: 'analyze',
      executable: 'flutter',
      arguments: <String>['analyze'],
    );
  }

  static FlutterCommand testWithCoverage() {
    return const FlutterCommand(
      stepName: 'tests',
      executable: 'flutter',
      arguments: <String>['test', '--coverage'],
    );
  }
}
