import 'package:flutter_ci_guard/src/process/flutter_commands.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterCommands', () {
    test('format command has correct properties', () {
      final command = FlutterCommands.format();
      expect(command.stepName, equals('format'));
      expect(command.executable, equals('dart'));
      expect(
        command.arguments,
        containsAll(['format', '--set-exit-if-changed', '.']),
      );
    });

    test('analyze command has correct properties', () {
      final command = FlutterCommands.analyze();
      expect(command.stepName, equals('analyze'));
      expect(command.executable, equals('flutter'));
      expect(command.arguments, contains('analyze'));
    });

    test('testWithCoverage command has correct properties', () {
      final command = FlutterCommands.testWithCoverage();
      expect(command.stepName, equals('tests'));
      expect(command.executable, equals('flutter'));
      expect(command.arguments, containsAll(['test', '--coverage']));
    });
  });
}
