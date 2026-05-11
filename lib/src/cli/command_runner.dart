import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import '../core/ci_guard.dart';
import '../core/exit_codes.dart';
import '../core/result.dart';
import '../output/console.dart';
import '../process/command_executor.dart';
import '../coverage/coverage_checker.dart';
import '../coverage/lcov_parser.dart';
import '../report/guard_report.dart';
import '../report/github_annotations_reporter.dart';
import 'options_parser.dart';
import 'options.dart';

Future<int> runFlutterCiGuard(
  List<String> args, {
  OptionsParser optionsParser = const OptionsParser(),
  CommandExecutor executor = const ProcessCommandExecutor(),
  CoverageChecker? coverageChecker,
  void Function(String message)? outputWriter,
  String? workingDirectory,
}) async {
  final Console defaultConsole = Console(writer: outputWriter);
  final ArgParser argParser = optionsParser.buildParser();

  try {
    final ArgResults argResults = argParser.parse(args);
    final bool jsonToStdout = argResults['json'] as bool;
    final Console console = jsonToStdout
        ? const Console(writer: _noopWrite)
        : defaultConsole;

    if (argResults['help'] as bool) {
      defaultConsole.info(optionsParser.getUsage(argParser));
      return ExitCodes.success;
    }

    final CiGuardOptions options = optionsParser.parse(
      args,
      workingDirectory: workingDirectory,
    );

    console.section('flutter_ci_guard');
    console.info('min coverage : ${options.minCoverage}%');
    console.info('coverage path: ${options.coveragePath}');
    console.info('exclude files: ${options.coverageExclude.length}');
    console.info('skip format  : ${options.skipFormat}');
    console.info('skip analyze : ${options.skipAnalyze}');
    console.info('skip tests   : ${options.skipTests}');

    final CiGuard guard = CiGuard(
      executor: executor,
      console: console,
      coverageChecker:
          coverageChecker ?? CoverageChecker(parser: const LcovParser()),
    );

    final result = await guard.run(options);
    await _emitJsonReport(
      options: options,
      result: result,
      outputWriter: outputWriter ?? stdout.writeln,
    );
    _emitGitHubAnnotations(
      options: options,
      result: result,
      outputWriter: outputWriter ?? stdout.writeln,
    );
    return result.exitCode;
  } on FormatException catch (error) {
    defaultConsole.error('Invalid arguments: ${error.message}\n');
    defaultConsole.info(optionsParser.getUsage(argParser));
    return ExitCodes.invalidArguments;
  }
}

Future<void> _emitJsonReport({
  required CiGuardOptions options,
  required GuardRunResult result,
  required void Function(String message) outputWriter,
}) async {
  if (!options.json && options.jsonOutputPath == null) {
    return;
  }

  final String jsonReport = const JsonEncoder.withIndent(
    '  ',
  ).convert(GuardReport.fromRunResult(options, result).toJson());

  if (options.json) {
    outputWriter(jsonReport);
  }

  if (options.jsonOutputPath != null) {
    final File file = File(options.jsonOutputPath!);
    file.parent.createSync(recursive: true);
    await file.writeAsString(jsonReport);
  }
}

void _emitGitHubAnnotations({
  required CiGuardOptions options,
  required GuardRunResult result,
  required void Function(String message) outputWriter,
}) {
  if (options.json || !options.githubAnnotations) {
    return;
  }

  GitHubAnnotationsReporter(
    writer: outputWriter,
  ).reportLowCoverageFiles(options: options, result: result);
}

void _noopWrite(String _) {}
