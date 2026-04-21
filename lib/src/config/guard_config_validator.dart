import 'guard_config.dart';

/// Validates and converts decoded YAML into a [GuardConfig].
class GuardConfigValidator {
  /// Creates a const [GuardConfigValidator].
  const GuardConfigValidator();

  /// Validates [rawConfig] and returns a typed [GuardConfig].
  ///
  /// Throws a [FormatException] when the YAML structure or value types are
  /// invalid for the supported schema.
  GuardConfig validate(dynamic rawConfig) {
    if (rawConfig == null) {
      return const GuardConfig();
    }

    if (rawConfig is! Map) {
      throw const FormatException(
        'Config root must be a map with "steps" and/or "coverage" sections.',
      );
    }

    final dynamic rawSteps = rawConfig['steps'];
    if (rawSteps != null && rawSteps is! Map) {
      throw const FormatException('Config key "steps" must be a map.');
    }

    final dynamic rawCoverage = rawConfig['coverage'];
    if (rawCoverage != null && rawCoverage is! Map) {
      throw const FormatException('Config key "coverage" must be a map.');
    }

    final dynamic format = rawSteps?['format'];
    if (format != null && format is! bool) {
      throw const FormatException('Config key "steps.format" must be a bool.');
    }

    final dynamic analyze = rawSteps?['analyze'];
    if (analyze != null && analyze is! bool) {
      throw const FormatException('Config key "steps.analyze" must be a bool.');
    }

    final dynamic test = rawSteps?['test'];
    if (test != null && test is! bool) {
      throw const FormatException('Config key "steps.test" must be a bool.');
    }

    final dynamic minCoverage = rawCoverage?['min'];
    if (minCoverage != null && minCoverage is! int) {
      throw const FormatException('Config key "coverage.min" must be an int.');
    }

    if (minCoverage != null && (minCoverage < 0 || minCoverage > 100)) {
      throw const FormatException(
        'Config key "coverage.min" must be between 0 and 100.',
      );
    }

    final dynamic coveragePath = rawCoverage?['path'];
    if (coveragePath != null && coveragePath is! String) {
      throw const FormatException(
        'Config key "coverage.path" must be a string.',
      );
    }

    if (coveragePath != null && coveragePath.trim().isEmpty) {
      throw const FormatException(
        'Config key "coverage.path" cannot be empty.',
      );
    }

    return GuardConfig(
      formatStepEnabled: format as bool?,
      analyzeStepEnabled: analyze as bool?,
      testStepEnabled: test as bool?,
      minCoverage: minCoverage as int?,
      coveragePath: coveragePath as String?,
    );
  }
}
