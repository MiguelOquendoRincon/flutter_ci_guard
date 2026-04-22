import 'dart:io';

import 'package:flutter_ci_guard/src/cli/options.dart';
import 'package:flutter_ci_guard/src/cli/options_parser.dart';
import 'package:test/test.dart';

void main() {
  group('OptionsParser', () {
    const parser = OptionsParser();
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flutter_ci_guard_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('parses default values correctly', () {
      final options = parser.parse([]);
      expect(options.minCoverage, equals(80));
      expect(options.coveragePath, equals('coverage/lcov.info'));
      expect(options.coverageExclude, isEmpty);
      expect(options.skipFormat, isFalse);
      expect(options.skipAnalyze, isFalse);
      expect(options.skipTests, isFalse);
    });

    test('parses custom values correctly', () {
      final options = parser.parse([
        '--min-coverage',
        '90',
        '--coverage-path',
        'custom/lcov.info',
        '--coverage-exclude',
        '**/*.g.dart,**/*.freezed.dart',
        '--skip-format',
        '--skip-analyze',
        '--skip-tests',
      ]);
      expect(options.minCoverage, equals(90));
      expect(options.coveragePath, equals('custom/lcov.info'));
      expect(
        options.coverageExclude,
        equals(const <String>['**/*.g.dart', '**/*.freezed.dart']),
      );
      expect(options.skipFormat, isTrue);
      expect(options.skipAnalyze, isTrue);
      expect(options.skipTests, isTrue);
    });

    test('throws FormatException for invalid min-coverage', () {
      expect(
        () => parser.parse(['--min-coverage', 'abc']),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for out of range min-coverage', () {
      expect(
        () => parser.parse(['--min-coverage', '110']),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parser.parse(['--min-coverage', '-5']),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for empty coverage-path', () {
      // Note: ArgParser might catch missing values, but our manual validation handles empty strings
      expect(
        () => parser.parse(['--coverage-path', ' ']),
        throwsA(isA<FormatException>()),
      );
    });

    test('loads flutter_ci_guard.yaml from working directory', () {
      final configFile = File('${tempDir.path}/flutter_ci_guard.yaml');
      configFile.writeAsStringSync('''
steps:
  format: false
  analyze: true
  test: false
coverage:
  min: 85
  path: custom/lcov.info
  exclude:
    - "**/*.g.dart"
    - "**/generated/**"
''');

      final options = parser.parse([], workingDirectory: tempDir.path);

      expect(options.minCoverage, equals(85));
      expect(options.coveragePath, equals('custom/lcov.info'));
      expect(
        options.coverageExclude,
        equals(const <String>['**/*.g.dart', '**/generated/**']),
      );
      expect(options.skipFormat, isTrue);
      expect(options.skipAnalyze, isFalse);
      expect(options.skipTests, isTrue);
    });

    test('merges partial config with defaults', () {
      final configFile = File('${tempDir.path}/flutter_ci_guard.yaml');
      configFile.writeAsStringSync('''
coverage:
  min: 92
''');

      final options = parser.parse([], workingDirectory: tempDir.path);

      expect(options.minCoverage, equals(92));
      expect(options.coveragePath, equals(CiGuardOptions.defaultCoveragePath));
      expect(options.skipFormat, isFalse);
      expect(options.skipAnalyze, isFalse);
      expect(options.skipTests, isFalse);
    });

    test('CLI arguments override YAML config values', () {
      final configFile = File('${tempDir.path}/flutter_ci_guard.yaml');
      configFile.writeAsStringSync('''
steps:
  format: true
  analyze: false
  test: true
coverage:
  min: 70
  path: from-config.info
  exclude:
    - "**/*.g.dart"
''');

      final options = parser.parse([
        '--min-coverage',
        '95',
        '--coverage-path',
        'from-cli.info',
        '--coverage-exclude',
        '**/*.freezed.dart',
        '--skip-format',
        '--skip-tests',
      ], workingDirectory: tempDir.path);

      expect(options.minCoverage, equals(95));
      expect(options.coveragePath, equals('from-cli.info'));
      expect(
        options.coverageExclude,
        equals(const <String>['**/*.freezed.dart']),
      );
      expect(options.skipFormat, isTrue);
      expect(options.skipAnalyze, isTrue);
      expect(options.skipTests, isTrue);
    });

    test('loads config from explicit --config path', () {
      final configFile = File('${tempDir.path}/custom.yaml');
      configFile.writeAsStringSync('''
coverage:
  min: 88
''');

      final options = parser.parse(['--config', configFile.path]);

      expect(options.minCoverage, equals(88));
      expect(options.coveragePath, equals(CiGuardOptions.defaultCoveragePath));
    });

    test('throws FormatException for missing explicit config file', () {
      expect(
        () => parser.parse(['--config', '${tempDir.path}/missing.yaml']),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Config file not found'),
          ),
        ),
      );
    });

    test('throws FormatException for invalid YAML config', () {
      final configFile = File('${tempDir.path}/flutter_ci_guard.yaml');
      configFile.writeAsStringSync('steps: [');

      expect(
        () => parser.parse([], workingDirectory: tempDir.path),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Invalid YAML'),
          ),
        ),
      );
    });

    test('throws FormatException for invalid config value types', () {
      final configFile = File('${tempDir.path}/flutter_ci_guard.yaml');
      configFile.writeAsStringSync('''
coverage:
  min: "high"
''');

      expect(
        () => parser.parse([], workingDirectory: tempDir.path),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('coverage.min'),
          ),
        ),
      );
    });

    test('throws FormatException for invalid coverage.exclude type', () {
      final configFile = File('${tempDir.path}/flutter_ci_guard.yaml');
      configFile.writeAsStringSync('''
coverage:
  exclude: invalid
''');

      expect(
        () => parser.parse([], workingDirectory: tempDir.path),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('coverage.exclude'),
          ),
        ),
      );
    });

    test('getUsage returns formatted string', () {
      final argParser = parser.buildParser();
      final usage = parser.getUsage(argParser);
      expect(usage, contains('Run Flutter quality gates in CI/CD.'));
      expect(usage, contains('--min-coverage'));
      expect(usage, contains('--coverage-exclude'));
      expect(usage, contains('--config'));
    });
  });
}
