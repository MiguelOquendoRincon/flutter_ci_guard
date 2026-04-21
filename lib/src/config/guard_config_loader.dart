import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'guard_config.dart';
import 'guard_config_validator.dart';

/// Loads `flutter_ci_guard` YAML configuration from disk.
class GuardConfigLoader {
  /// Creates a [GuardConfigLoader].
  const GuardConfigLoader({this.validator = const GuardConfigValidator()});

  /// Validator used to convert raw YAML into typed config.
  final GuardConfigValidator validator;

  /// Loads config from [configPath] or from `flutter_ci_guard.yaml` in
  /// [workingDirectory] when no explicit path is provided.
  ///
  /// Throws a [FormatException] when an explicit config file is missing, the
  /// YAML is invalid, or the config contains unsupported value types.
  GuardConfig load({String? configPath, String? workingDirectory}) {
    final String resolvedWorkingDirectory =
        workingDirectory ?? Directory.current.path;

    final String resolvedPath = configPath != null
        ? p.normalize(
            p.isAbsolute(configPath)
                ? configPath
                : p.join(resolvedWorkingDirectory, configPath),
          )
        : p.join(resolvedWorkingDirectory, 'flutter_ci_guard.yaml');

    final File file = File(resolvedPath);
    if (!file.existsSync()) {
      if (configPath != null) {
        throw FormatException('Config file not found: $configPath');
      }
      return const GuardConfig();
    }

    final String contents = file.readAsStringSync();

    try {
      final dynamic decoded = loadYaml(contents);
      return validator.validate(decoded);
    } on YamlException catch (error) {
      throw FormatException(
        'Invalid YAML in config file "$resolvedPath": ${error.message}',
      );
    } on FormatException catch (error) {
      throw FormatException(
        'Invalid config file "$resolvedPath": ${error.message}',
      );
    }
  }
}
