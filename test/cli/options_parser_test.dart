import 'package:flutter_ci_guard/src/cli/options_parser.dart';
import 'package:test/test.dart';

void main() {
  group('OptionsParser', () {
    const parser = OptionsParser();

    test('parses default values correctly', () {
      final options = parser.parse([]);
      expect(options.minCoverage, equals(80));
      expect(options.coveragePath, equals('coverage/lcov.info'));
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
        '--skip-format',
        '--skip-analyze',
        '--skip-tests',
      ]);
      expect(options.minCoverage, equals(90));
      expect(options.coveragePath, equals('custom/lcov.info'));
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

    test('getUsage returns formatted string', () {
      final argParser = parser.buildParser();
      final usage = parser.getUsage(argParser);
      expect(usage, contains('Run Flutter quality gates in CI/CD.'));
      expect(usage, contains('--min-coverage'));
    });
  });
}
