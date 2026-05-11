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
        'Config root must be a map with "steps", "coverage", and/or "output" sections.',
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

    final dynamic rawOutput = rawConfig['output'];
    if (rawOutput != null && rawOutput is! Map) {
      throw const FormatException('Config key "output" must be a map.');
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

    final dynamic coverageExclude = rawCoverage?['exclude'];
    if (coverageExclude != null && coverageExclude is! List) {
      throw const FormatException(
        'Config key "coverage.exclude" must be a list of strings.',
      );
    }

    if (coverageExclude != null &&
        coverageExclude.any((dynamic item) => item is! String)) {
      throw const FormatException(
        'Config key "coverage.exclude" must be a list of strings.',
      );
    }

    final dynamic perFileMinCoverage = rawCoverage?['per_file_min'];
    if (perFileMinCoverage != null && perFileMinCoverage is! int) {
      throw const FormatException(
        'Config key "coverage.per_file_min" must be an int.',
      );
    }

    if (perFileMinCoverage != null &&
        (perFileMinCoverage < 0 || perFileMinCoverage > 100)) {
      throw const FormatException(
        'Config key "coverage.per_file_min" must be between 0 and 100.',
      );
    }

    final dynamic showTopLowFiles = rawCoverage?['show_top_low_files'];
    if (showTopLowFiles != null && showTopLowFiles is! int) {
      throw const FormatException(
        'Config key "coverage.show_top_low_files" must be an int.',
      );
    }

    if (showTopLowFiles != null && showTopLowFiles < 1) {
      throw const FormatException(
        'Config key "coverage.show_top_low_files" must be greater than 0.',
      );
    }

    final dynamic githubAnnotations = rawOutput?['github_annotations'];
    if (githubAnnotations != null && githubAnnotations is! bool) {
      throw const FormatException(
        'Config key "output.github_annotations" must be a bool.',
      );
    }

    return GuardConfig(
      formatStepEnabled: format as bool?,
      analyzeStepEnabled: analyze as bool?,
      testStepEnabled: test as bool?,
      minCoverage: minCoverage as int?,
      coveragePath: coveragePath as String?,
      coverageExclude: (coverageExclude as List<dynamic>?)
          ?.cast<String>()
          .map((String pattern) => pattern.trim())
          .where((String pattern) => pattern.isNotEmpty)
          .toList(growable: false),
      perFileMinCoverage: perFileMinCoverage as int?,
      showTopLowFiles: showTopLowFiles as int?,
      githubAnnotations: githubAnnotations as bool?,
    );
  }
}
