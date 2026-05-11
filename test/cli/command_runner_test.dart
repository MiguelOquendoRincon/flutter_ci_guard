import 'dart:convert';
import 'dart:io';

import 'package:flutter_ci_guard/src/cli/command_runner.dart';
import 'package:flutter_ci_guard/src/core/exit_codes.dart';
import 'package:flutter_ci_guard/src/core/result.dart';
import 'package:flutter_ci_guard/src/process/command_executor.dart';
import 'package:test/test.dart';

class FakeCommandExecutor implements CommandExecutor {
  FakeCommandExecutor(this._results);

  final List<StepResult> _results;
  int _index = 0;

  @override
  Future<StepResult> run({
    required String stepName,
    required String executable,
    required List<String> arguments,
  }) async {
    final StepResult result = _results[_index];
    _index += 1;
    return result;
  }
}

void main() {
  group('runFlutterCiGuard JSON output', () {
    late Directory tempDir;
    late File coverageFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flutter_ci_guard_runner_');
      coverageFile = File('${tempDir.path}/lcov.info')
        ..writeAsStringSync('''
TN:
SF:lib/main.dart
DA:1,1
DA:2,0
DA:3,1
end_of_record
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('prints only JSON to stdout when --json is used', () async {
      final StringBuffer buffer = StringBuffer();

      final exitCode = await runFlutterCiGuard(
        <String>['--json', '--coverage-path', coverageFile.path],
        executor: FakeCommandExecutor(const <StepResult>[
          StepResult(
            name: 'format',
            success: true,
            exitCode: 0,
            durationMs: 800,
          ),
          StepResult(
            name: 'analyze',
            success: true,
            exitCode: 0,
            durationMs: 4100,
          ),
          StepResult(
            name: 'tests',
            success: true,
            exitCode: 0,
            durationMs: 18000,
          ),
        ]),
        outputWriter: (String message) => buffer.writeln(message),
      );

      final Map<String, dynamic> json =
          jsonDecode(buffer.toString()) as Map<String, dynamic>;

      expect(exitCode, equals(ExitCodes.coverageBelowThreshold));
      expect(json['success'], isFalse);
      expect(json['exit_code'], equals(ExitCodes.coverageBelowThreshold));
      expect(json['steps'], hasLength(3));
      expect(
        (json['coverage'] as Map<String, dynamic>)['lines_found'],
        equals(3),
      );
    });

    test('writes JSON to a file when --json-output is used', () async {
      final String outputPath = '${tempDir.path}/reports/report.json';

      final exitCode = await runFlutterCiGuard(<String>[
        '--skip-format',
        '--skip-analyze',
        '--skip-tests',
        '--coverage-path',
        coverageFile.path,
        '--json-output',
        outputPath,
        '--min-coverage',
        '60',
      ], executor: FakeCommandExecutor(const <StepResult>[]));

      final Map<String, dynamic> json =
          jsonDecode(File(outputPath).readAsStringSync())
              as Map<String, dynamic>;

      expect(exitCode, equals(ExitCodes.success));
      expect(json['success'], isTrue);
      expect(json['exit_code'], equals(ExitCodes.success));
      expect(
        (json['coverage'] as Map<String, dynamic>)['global_percentage'],
        closeTo(66.67, 0.01),
      );
    });

    test('prints and writes JSON when both flags are used', () async {
      final String outputPath = '${tempDir.path}/report.json';
      final StringBuffer buffer = StringBuffer();

      final exitCode = await runFlutterCiGuard(
        <String>[
          '--json',
          '--json-output',
          outputPath,
          '--skip-format',
          '--skip-analyze',
          '--skip-tests',
          '--coverage-path',
          coverageFile.path,
          '--min-coverage',
          '60',
        ],
        executor: FakeCommandExecutor(const <StepResult>[]),
        outputWriter: (String message) => buffer.writeln(message),
      );

      final String stdoutJson = buffer.toString().trim();
      final String fileJson = File(outputPath).readAsStringSync().trim();

      expect(exitCode, equals(ExitCodes.success));
      expect(stdoutJson, equals(fileJson));
    });

    test('serializes empty low_files lists', () async {
      final StringBuffer buffer = StringBuffer();

      await runFlutterCiGuard(
        <String>[
          '--json',
          '--skip-format',
          '--skip-analyze',
          '--skip-tests',
          '--coverage-path',
          coverageFile.path,
          '--min-coverage',
          '60',
        ],
        executor: FakeCommandExecutor(const <StepResult>[]),
        outputWriter: (String message) => buffer.writeln(message),
      );

      final Map<String, dynamic> json =
          jsonDecode(buffer.toString()) as Map<String, dynamic>;

      expect((json['coverage'] as Map<String, dynamic>)['low_files'], isEmpty);
    });

    test('handles missing coverage files gracefully in JSON', () async {
      final StringBuffer buffer = StringBuffer();

      final exitCode = await runFlutterCiGuard(
        <String>[
          '--json',
          '--skip-format',
          '--skip-analyze',
          '--skip-tests',
          '--coverage-path',
          '${tempDir.path}/missing.info',
        ],
        executor: FakeCommandExecutor(const <StepResult>[]),
        outputWriter: (String message) => buffer.writeln(message),
      );

      final Map<String, dynamic> json =
          jsonDecode(buffer.toString()) as Map<String, dynamic>;
      final Map<String, dynamic> coverage =
          json['coverage'] as Map<String, dynamic>;

      expect(exitCode, equals(ExitCodes.coverageFileNotFound));
      expect(json['success'], isFalse);
      expect(json['exit_code'], equals(ExitCodes.coverageFileNotFound));
      expect(coverage['global_percentage'], equals(0.0));
      expect(coverage['lines_found'], equals(0));
      expect(coverage['lines_hit'], equals(0));
      expect(coverage['low_files'], isEmpty);
    });
  });
}
