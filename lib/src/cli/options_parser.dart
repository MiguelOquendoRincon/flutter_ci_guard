import 'package:args/args.dart';

import '../config/guard_config_loader.dart';
import '../config/guard_config_merger.dart';
import 'options.dart';

/// Builds the CLI argument parser and maps raw arguments to [CiGuardOptions].
///
/// Separating argument parsing from [runFlutterCiGuard] makes it possible to
/// test all validation logic in isolation without spawning a full process.
class OptionsParser {
  /// Creates a const [OptionsParser].
  const OptionsParser({
    this.configLoader = const GuardConfigLoader(),
    this.configMerger = const GuardConfigMerger(),
  });

  /// Loads YAML config from disk.
  final GuardConfigLoader configLoader;

  /// Merges defaults, YAML config, and explicit CLI arguments.
  final GuardConfigMerger configMerger;

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
        defaultsTo: '${CiGuardOptions.defaultMinCoverage}',
        help: 'Minimum required total coverage percentage.',
        valueHelp: 'int',
      )
      ..addOption(
        'coverage-path',
        defaultsTo: CiGuardOptions.defaultCoveragePath,
        help: 'Path to the lcov.info file.',
        valueHelp: 'path',
      )
      ..addOption(
        'config',
        help: 'Path to a flutter_ci_guard YAML config file.',
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
  /// - `--config` points to a missing or invalid YAML file.
  /// - `--min-coverage` is not a valid integer.
  /// - `--min-coverage` is outside the range `[0, 100]`.
  /// - `--coverage-path` is empty or blank.
  CiGuardOptions parse(List<String> args, {String? workingDirectory}) {
    final ArgParser parser = buildParser();
    final ArgResults results = parser.parse(args);

    if (results.wasParsed('min-coverage') &&
        int.tryParse(results['min-coverage'] as String) == null) {
      throw const FormatException('--min-coverage must be a valid integer.');
    }

    final config = configLoader.load(
      configPath: results['config'] as String?,
      workingDirectory: workingDirectory,
    );

    final CiGuardOptions options = configMerger.merge(
      yamlConfig: config,
      cliResults: results,
    );

    if (options.minCoverage < 0 || options.minCoverage > 100) {
      throw const FormatException('--min-coverage must be between 0 and 100.');
    }

    if (options.coveragePath.trim().isEmpty) {
      throw const FormatException('--coverage-path cannot be empty.');
    }

    return options;
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
