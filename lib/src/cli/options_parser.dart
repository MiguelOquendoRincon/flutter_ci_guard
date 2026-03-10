import 'package:args/args.dart';
import 'options.dart';

class OptionsParser {
  const OptionsParser();

  ArgParser buildParser() {
    return ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show usage information.',
      )
      ..addOption(
        'min-coverage',
        defaultsTo: '80',
        help: 'Minimum required total coverage percentage.',
        valueHelp: 'int',
      )
      ..addOption(
        'coverage-path',
        defaultsTo: 'coverage/lcov.info',
        help: 'Path to the lcov.info file.',
        valueHelp: 'path',
      )
      ..addFlag(
        'skip-format',
        negatable: false,
        help: 'Skip flutter format validation.',
      )
      ..addFlag('skip-analyze', negatable: false, help: 'Skip flutter analyze.')
      ..addFlag(
        'skip-tests',
        negatable: false,
        help: 'Skip flutter test --coverage.',
      );
  }

  CiGuardOptions parse(List<String> args) {
    final ArgParser parser = buildParser();
    final ArgResults results = parser.parse(args);

    final int minCoverage =
        int.tryParse(results['min-coverage'] as String) ??
        (throw const FormatException(
          '--min-coverage must be a valid integer.',
        ));

    if (minCoverage < 0 || minCoverage > 100) {
      throw const FormatException('--min-coverage must be between 0 and 100.');
    }

    final String coveragePath = results['coverage-path'] as String;
    if (coveragePath.trim().isEmpty) {
      throw const FormatException('--coverage-path cannot be empty.');
    }

    return CiGuardOptions(
      minCoverage: minCoverage,
      coveragePath: coveragePath,
      skipFormat: results['skip-format'] as bool,
      skipAnalyze: results['skip-analyze'] as bool,
      skipTests: results['skip-tests'] as bool,
    );
  }

  String getUsage(ArgParser parser) {
    return '''
Run Flutter quality gates in CI/CD.

Usage:
  dart run flutter_ci_guard [options]

Options:
${parser.usage}
''';
  }
}
