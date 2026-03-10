import 'package:args/args.dart';

import '../core/ci_guard.dart';
import '../core/exit_codes.dart';
import '../output/console.dart';
import '../process/command_executor.dart';
import 'options.dart';

Future<int> runFlutterCiGuard(List<String> args) async {
  final Console console = const Console();
  final ArgParser parser = _buildParser();

  try {
    final ArgResults results = parser.parse(args);

    if (results['help'] as bool) {
      console.info(_usage(parser));
      return ExitCodes.success;
    }

    final CiGuardOptions options = _mapOptions(results);

    console.section('flutter_ci_guard');
    console.info('min coverage : ${options.minCoverage}%');
    console.info('coverage path: ${options.coveragePath}');
    console.info('skip format  : ${options.skipFormat}');
    console.info('skip analyze : ${options.skipAnalyze}');
    console.info('skip tests   : ${options.skipTests}');

    final CiGuard guard = CiGuard(
      executor: const ProcessCommandExecutor(),
      console: console,
    );

    final result = await guard.run(options);
    return result.exitCode;
  } on FormatException catch (error) {
    console.error('Invalid arguments: ${error.message}\n');
    console.info(_usage(parser));
    return ExitCodes.invalidArguments;
  }
}

ArgParser _buildParser() {
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

CiGuardOptions _mapOptions(ArgResults results) {
  final int minCoverage =
      int.tryParse(results['min-coverage'] as String) ??
      (throw const FormatException('--min-coverage must be a valid integer.'));

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

String _usage(ArgParser parser) {
  return '''
Run Flutter quality gates in CI/CD.

Usage:
  dart run flutter_ci_guard [options]

Options:
${parser.usage}
''';
}
