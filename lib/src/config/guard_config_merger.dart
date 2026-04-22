import 'package:args/args.dart';

import '../cli/options.dart';
import 'guard_config.dart';

/// Merges defaults, YAML config, and explicit CLI arguments.
class GuardConfigMerger {
  /// Creates a const [GuardConfigMerger].
  const GuardConfigMerger();

  /// Returns the final [CiGuardOptions] using precedence:
  /// CLI > YAML > defaults.
  CiGuardOptions merge({
    required GuardConfig yamlConfig,
    required ArgResults cliResults,
  }) {
    final int minCoverage = cliResults.wasParsed('min-coverage')
        ? int.parse(cliResults['min-coverage'] as String)
        : (yamlConfig.minCoverage ?? CiGuardOptions.defaultMinCoverage);

    final String coveragePath = cliResults.wasParsed('coverage-path')
        ? cliResults['coverage-path'] as String
        : (yamlConfig.coveragePath ?? CiGuardOptions.defaultCoveragePath);

    final List<String> coverageExclude =
        cliResults.wasParsed('coverage-exclude')
        ? _parseCoverageExclude(cliResults['coverage-exclude'] as String)
        : (yamlConfig.coverageExclude ?? const <String>[]);

    final bool skipFormat = cliResults.wasParsed('skip-format')
        ? cliResults['skip-format'] as bool
        : !(yamlConfig.formatStepEnabled ?? true);

    final bool skipAnalyze = cliResults.wasParsed('skip-analyze')
        ? cliResults['skip-analyze'] as bool
        : !(yamlConfig.analyzeStepEnabled ?? true);

    final bool skipTests = cliResults.wasParsed('skip-tests')
        ? cliResults['skip-tests'] as bool
        : !(yamlConfig.testStepEnabled ?? true);

    return CiGuardOptions(
      minCoverage: minCoverage,
      coveragePath: coveragePath,
      coverageExclude: coverageExclude,
      skipFormat: skipFormat,
      skipAnalyze: skipAnalyze,
      skipTests: skipTests,
    );
  }

  List<String> _parseCoverageExclude(String rawValue) {
    return rawValue
        .split(',')
        .map((String pattern) => pattern.trim())
        .where((String pattern) => pattern.isNotEmpty)
        .toList(growable: false);
  }
}
