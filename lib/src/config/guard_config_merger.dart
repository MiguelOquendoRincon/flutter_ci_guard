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
      skipFormat: skipFormat,
      skipAnalyze: skipAnalyze,
      skipTests: skipTests,
    );
  }
}
