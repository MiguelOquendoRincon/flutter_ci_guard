import 'package:args/args.dart';

import 'options.dart';

/// Builds the CLI argument parser and maps raw arguments to [CiGuardOptions].
///
/// Separating argument parsing from [runFlutterCiGuard] makes it possible to
/// test all validation logic in isolation without spawning a full process.
class OptionsParser {
  /// Creates a const [OptionsParser].
  const OptionsParser();

  /// Constructs and returns the [ArgParser] configured with all supported flags
  /// and options.
  ///
  /// The returned parser is safe to reuse for both parsing and generating
  /// usage text.
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

  /// Parses [args] and returns a validated [CiGuardOptions].
  ///
  /// Throws a [FormatException] if:
  /// - `--min-coverage` is not a valid integer.
  /// - `--min-coverage` is outside the range `[0, 100]`.
  /// - `--coverage-path` is empty or blank.
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

  /// Returns the formatted usage string for the CLI.
  ///
  /// The [parser] should be the instance returned by [buildParser].
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
