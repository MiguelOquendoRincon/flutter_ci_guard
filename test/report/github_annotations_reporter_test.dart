import 'package:flutter_ci_guard/src/cli/options.dart';
import 'package:flutter_ci_guard/src/core/result.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_checker.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_summary.dart';
import 'package:flutter_ci_guard/src/coverage/file_coverage_record.dart';
import 'package:flutter_ci_guard/src/report/github_annotations_reporter.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubAnnotationsReporter', () {
    test('escapes workflow command values safely', () {
      const GitHubAnnotationsReporter reporter = GitHubAnnotationsReporter();

      expect(
        reporter.escapeWorkflowCommandValue(
          'lib/a,b:c.dart\r\n50%',
          escapeMetadata: true,
        ),
        equals('lib/a%2Cb%3Ac.dart%0D%0A50%25'),
      );
      expect(
        reporter.escapeWorkflowCommandValue('Coverage is 50%\nBelow target\r'),
        equals('Coverage is 50%25%0ABelow target%0D'),
      );
    });

    test('caps annotations to 10 by default when no limit is configured', () {
      final List<String> messages = <String>[];
      final GitHubAnnotationsReporter reporter = GitHubAnnotationsReporter(
        writer: messages.add,
      );

      reporter.reportLowCoverageFiles(
        options: _options(),
        result: GuardRunResult(
          success: false,
          exitCode: 2,
          completedSteps: const <StepResult>[],
          coverageResult: CoverageCheckResult(
            success: false,
            exitCode: 2,
            summary: const CoverageSummary(linesFound: 12, linesHit: 0),
            minimumCoverage: 80,
            excludedFilesCount: 0,
            includedFilesCount: 12,
            lowCoverageFiles: List<FileCoverageRecord>.generate(
              12,
              (int index) => FileCoverageRecord(
                path: 'lib/file_$index.dart',
                linesFound: 10,
                linesHit: 0,
              ),
              growable: false,
            ),
          ),
        ),
      );

      expect(messages, hasLength(10));
      expect(messages.first, startsWith('::error '));
    });

    test('serializes file path and percentage in the annotation payload', () {
      final List<String> messages = <String>[];
      final GitHubAnnotationsReporter reporter = GitHubAnnotationsReporter(
        writer: messages.add,
      );

      reporter.reportLowCoverageFiles(
        options: _options(perFileMinCoverage: 70),
        result: const GuardRunResult(
          success: true,
          exitCode: 0,
          completedSteps: const <StepResult>[],
          coverageResult: const CoverageCheckResult(
            success: true,
            exitCode: 0,
            summary: CoverageSummary(linesFound: 100, linesHit: 54),
            minimumCoverage: 80,
            excludedFilesCount: 0,
            includedFilesCount: 1,
            lowCoverageFiles: <FileCoverageRecord>[
              FileCoverageRecord(
                path: 'lib/auth/login_cubit.dart',
                linesFound: 100,
                linesHit: 54,
              ),
            ],
          ),
        ),
      );

      expect(messages, hasLength(1));
      expect(
        messages.single,
        equals(
          '::warning '
          'file=lib/auth/login_cubit.dart,line=1,title=Low coverage'
          '::Coverage is 54.00%25, below required 70.00%25',
        ),
      );
    });

    test('escapes special characters in file path and message payload', () {
      final List<String> messages = <String>[];
      final GitHubAnnotationsReporter reporter = GitHubAnnotationsReporter(
        writer: messages.add,
      );

      reporter.reportLowCoverageFiles(
        options: _options(perFileMinCoverage: 70),
        result: const GuardRunResult(
          success: true,
          exitCode: 0,
          completedSteps: const <StepResult>[],
          coverageResult: const CoverageCheckResult(
            success: true,
            exitCode: 0,
            summary: CoverageSummary(linesFound: 10, linesHit: 5),
            minimumCoverage: 80,
            excludedFilesCount: 0,
            includedFilesCount: 1,
            lowCoverageFiles: <FileCoverageRecord>[
              FileCoverageRecord(
                path: 'lib/a,b:c.dart\ncopy',
                linesFound: 10,
                linesHit: 5,
              ),
            ],
          ),
        ),
      );

      expect(messages, hasLength(1));
      expect(
        messages.single,
        contains('file=lib/a%2Cb%3Ac.dart%0Acopy,line=1,title=Low coverage'),
      );
      expect(
        messages.single,
        contains('::Coverage is 50.00%25, below required 70.00%25'),
      );
    });

    test('emits no annotations when there are no low coverage files', () {
      final List<String> messages = <String>[];
      final GitHubAnnotationsReporter reporter = GitHubAnnotationsReporter(
        writer: messages.add,
      );

      reporter.reportLowCoverageFiles(
        options: _options(githubAnnotations: true, perFileMinCoverage: 70),
        result: const GuardRunResult(
          success: true,
          exitCode: 0,
          completedSteps: <StepResult>[],
          coverageResult: CoverageCheckResult(
            success: true,
            exitCode: 0,
            summary: CoverageSummary(linesFound: 10, linesHit: 9),
            minimumCoverage: 80,
            excludedFilesCount: 0,
            includedFilesCount: 1,
            lowCoverageFiles: <FileCoverageRecord>[],
          ),
        ),
      );

      expect(messages, isEmpty);
    });
  });
}

CiGuardOptions _options({
  int? perFileMinCoverage,
  int? showTopLowFiles,
  bool githubAnnotations = true,
}) {
  return CiGuardOptions(
    minCoverage: 80,
    coveragePath: 'coverage/lcov.info',
    coverageExclude: const <String>[],
    perFileMinCoverage: perFileMinCoverage,
    showTopLowFiles: showTopLowFiles,
    githubAnnotations: githubAnnotations,
    skipFormat: true,
    skipAnalyze: true,
    skipTests: true,
    json: false,
    jsonOutputPath: null,
  );
}
