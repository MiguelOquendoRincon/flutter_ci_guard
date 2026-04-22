import 'package:args/args.dart';

import '../core/ci_guard.dart';
import '../core/exit_codes.dart';
import '../output/console.dart';
import '../process/command_executor.dart';
import 'options_parser.dart';
import 'options.dart';

Future<int> runFlutterCiGuard(List<String> args) async {
  final Console console = const Console();
  const OptionsParser optionsParser = OptionsParser();
  final ArgParser argParser = optionsParser.buildParser();

  try {
    final ArgResults argResults = argParser.parse(args);

    if (argResults['help'] as bool) {
      console.info(optionsParser.getUsage(argParser));
      return ExitCodes.success;
    }

    final CiGuardOptions options = optionsParser.parse(args);

    console.section('flutter_ci_guard');
    console.info('min coverage : ${options.minCoverage}%');
    console.info('coverage path: ${options.coveragePath}');
    console.info('exclude files: ${options.coverageExclude.length}');
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
    console.info(optionsParser.getUsage(argParser));
    return ExitCodes.invalidArguments;
  }
}
