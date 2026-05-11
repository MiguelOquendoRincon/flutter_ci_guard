import 'package:flutter_ci_guard/src/cli/options.dart';
import 'package:flutter_ci_guard/src/core/result.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_checker.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_summary.dart';
import 'package:flutter_ci_guard/src/coverage/file_coverage_record.dart';
import 'package:flutter_ci_guard/src/report/guard_report.dart';
import 'package:test/test.dart';

void main() {
  group('GuardReport', () {
    test('serializes the expected JSON structure', () {
      final options = CiGuardOptions(
        minCoverage: 85,
        coveragePath: 'coverage/lcov.info',
        coverageExclude: const <String>['**/*.g.dart'],
        perFileMinCoverage: 70,
        showTopLowFiles: 3,
        githubAnnotations: false,
        skipFormat: false,
        skipAnalyze: false,
        skipTests: false,
        json: true,
        jsonOutputPath: null,
      );

      final result = const GuardRunResult(
        success: true,
        exitCode: 0,
        completedSteps: <StepResult>[
          StepResult(
            name: 'format',
            success: true,
            exitCode: 0,
            durationMs: 800,
          ),
          StepResult(
            name: 'analyze',
            success: true,
            exitCode: 0,
            durationMs: 4100,
          ),
          StepResult(
            name: 'tests',
            success: true,
            exitCode: 0,
            durationMs: 18000,
          ),
        ],
        coverageResult: const CoverageCheckResult(
          success: true,
          exitCode: 0,
          summary: CoverageSummary(linesFound: 1000, linesHit: 824),
          minimumCoverage: 85,
          excludedFilesCount: 5,
          includedFilesCount: 10,
          lowCoverageFiles: <FileCoverageRecord>[
            FileCoverageRecord(
              path: 'lib/auth/login_cubit.dart',
              linesFound: 100,
              linesHit: 54,
            ),
          ],
        ),
      );

      final report = GuardReport.fromRunResult(options, result).toJson();

      expect(report['success'], isTrue);
      expect(report['exit_code'], equals(0));

      final steps = report['steps'] as List<dynamic>;
      expect(steps, hasLength(3));
      expect(
        steps[0],
        equals(<String, Object>{
          'name': 'format',
          'success': true,
          'duration_ms': 800,
        }),
      );
      expect(
        steps[1],
        equals(<String, Object>{
          'name': 'analyze',
          'success': true,
          'duration_ms': 4100,
        }),
      );
      expect(
        steps[2],
        equals(<String, Object>{
          'name': 'test',
          'success': true,
          'duration_ms': 18000,
        }),
      );

      final coverage = report['coverage'] as Map<String, Object>;
      expect(coverage['global_percentage'], closeTo(82.4, 0.001));
      expect(coverage['lines_found'], equals(1000));
      expect(coverage['lines_hit'], equals(824));
      expect(coverage['minimum_required'], equals(85));
      expect(coverage['excluded_files_count'], equals(5));
      expect(
        coverage['low_files'],
        equals(<Map<String, Object>>[
          <String, Object>{
            'path': 'lib/auth/login_cubit.dart',
            'percentage': 54.0,
          },
        ]),
      );
    });

    test(
      'uses stable empty coverage defaults when coverage is unavailable',
      () {
        final options = CiGuardOptions(
          minCoverage: 85,
          coveragePath: 'missing/lcov.info',
          coverageExclude: const <String>[],
          perFileMinCoverage: null,
          showTopLowFiles: null,
          githubAnnotations: false,
          skipFormat: true,
          skipAnalyze: true,
          skipTests: true,
          json: true,
          jsonOutputPath: null,
        );

        final result = const GuardRunResult(
          success: false,
          exitCode: 3,
          completedSteps: <StepResult>[],
        );

        final report = GuardReport.fromRunResult(options, result).toJson();
        final coverage = report['coverage'] as Map<String, Object>;

        expect(coverage['global_percentage'], equals(0.0));
        expect(coverage['lines_found'], equals(0));
        expect(coverage['lines_hit'], equals(0));
        expect(coverage['minimum_required'], equals(85));
        expect(coverage['excluded_files_count'], equals(0));
        expect(coverage['low_files'], isEmpty);
      },
    );
  });
}
