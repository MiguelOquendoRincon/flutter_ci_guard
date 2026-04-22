import 'dart:io';

import 'package:flutter_ci_guard/src/cli/options.dart';
import 'package:flutter_ci_guard/src/core/ci_guard.dart';
import 'package:flutter_ci_guard/src/core/exit_codes.dart';
import 'package:flutter_ci_guard/src/core/result.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_checker.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_summary.dart';
import 'package:flutter_ci_guard/src/coverage/lcov_parser.dart';
import 'package:flutter_ci_guard/src/output/console.dart';
import 'package:flutter_ci_guard/src/process/command_executor.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockCommandExecutor extends Mock implements CommandExecutor {}

class MockConsole extends Mock implements Console {}

class MockCoverageChecker extends Mock implements CoverageChecker {}

void main() {
  late CiGuard ciGuard;
  late MockCommandExecutor mockExecutor;
  late MockConsole mockConsole;
  late MockCoverageChecker mockCoverageChecker;

  setUp(() {
    mockExecutor = MockCommandExecutor();
    mockConsole = MockConsole();
    mockCoverageChecker = MockCoverageChecker();

    ciGuard = CiGuard(
      executor: mockExecutor,
      console: mockConsole,
      coverageChecker: mockCoverageChecker,
    );

    // Default mocks to avoid errors if not explicitly set in test
    when(() => mockConsole.section(any())).thenReturn(null);
    when(() => mockConsole.info(any())).thenReturn(null);
    when(() => mockConsole.error(any())).thenReturn(null);
  });

  group('CiGuard', () {
    test('runs all steps successfully and returns success', () async {
      final options = CiGuardOptions(
        minCoverage: 80,
        coveragePath: 'coverage/lcov.info',
        coverageExclude: const <String>[],
        skipFormat: false,
        skipAnalyze: false,
        skipTests: false,
      );

      when(
        () => mockExecutor.run(
          stepName: any(named: 'stepName'),
          executable: any(named: 'executable'),
          arguments: any(named: 'arguments'),
        ),
      ).thenAnswer(
        (_) async => const StepResult(name: 'step', success: true, exitCode: 0),
      );

      when(
        () => mockCoverageChecker.check(
          coveragePath: any(named: 'coveragePath'),
          minimumCoverage: any(named: 'minimumCoverage'),
          excludePatterns: any(named: 'excludePatterns'),
        ),
      ).thenReturn(
        const CoverageCheckResult(
          success: true,
          exitCode: 0,
          summary: CoverageSummary(linesFound: 10, linesHit: 9),
          minimumCoverage: 80,
          excludedFilesCount: 0,
          includedFilesCount: 1,
        ),
      );

      final result = await ciGuard.run(options);

      expect(result.success, isTrue);
      expect(result.exitCode, equals(ExitCodes.success));
      expect(result.completedSteps.length, equals(3));
      verify(() => mockConsole.info('✓ format passed')).called(1);
      verify(() => mockConsole.info('✓ analyze passed')).called(1);
      verify(() => mockConsole.info('✓ tests passed')).called(1);
      verify(() => mockConsole.info('✓ coverage check passed')).called(1);
    });

    test('stops on first failed step (format)', () async {
      final options = CiGuardOptions(
        minCoverage: 80,
        coveragePath: 'coverage/lcov.info',
        coverageExclude: const <String>[],
        skipFormat: false,
        skipAnalyze: false,
        skipTests: false,
      );

      when(
        () => mockExecutor.run(
          stepName: any(named: 'stepName'),
          executable: any(named: 'executable'),
          arguments: any(named: 'arguments'),
        ),
      ).thenAnswer((invocation) async {
        final stepName = invocation.namedArguments[#stepName] as String;
        if (stepName == 'format') {
          return const StepResult(name: 'format', success: false, exitCode: 1);
        }
        return const StepResult(name: 'step', success: true, exitCode: 0);
      });

      final result = await ciGuard.run(options);

      expect(result.success, isFalse);
      expect(result.exitCode, equals(ExitCodes.commandFailed));
      expect(result.completedSteps.length, equals(1));
      expect(result.failedStep?.name, equals('format'));

      verifyNever(
        () => mockExecutor.run(
          stepName: 'analyze',
          executable: any(named: 'executable'),
          arguments: any(named: 'arguments'),
        ),
      );
    });

    test('skips steps if requested in options', () async {
      final options = CiGuardOptions(
        minCoverage: 80,
        coveragePath: 'coverage/lcov.info',
        coverageExclude: const <String>[],
        skipFormat: true,
        skipAnalyze: true,
        skipTests: false,
      );

      when(
        () => mockExecutor.run(
          stepName: any(named: 'stepName'),
          executable: any(named: 'executable'),
          arguments: any(named: 'arguments'),
        ),
      ).thenAnswer(
        (_) async => const StepResult(name: 'step', success: true, exitCode: 0),
      );

      when(
        () => mockCoverageChecker.check(
          coveragePath: any(named: 'coveragePath'),
          minimumCoverage: any(named: 'minimumCoverage'),
          excludePatterns: any(named: 'excludePatterns'),
        ),
      ).thenReturn(
        const CoverageCheckResult(
          success: true,
          exitCode: 0,
          summary: CoverageSummary(linesFound: 10, linesHit: 10),
          minimumCoverage: 80,
          excludedFilesCount: 0,
          includedFilesCount: 1,
        ),
      );

      await ciGuard.run(options);

      verifyNever(
        () => mockExecutor.run(
          stepName: 'format',
          executable: any(named: 'executable'),
          arguments: any(named: 'arguments'),
        ),
      );
      verifyNever(
        () => mockExecutor.run(
          stepName: 'analyze',
          executable: any(named: 'executable'),
          arguments: any(named: 'arguments'),
        ),
      );
      verify(
        () => mockExecutor.run(
          stepName: 'tests',
          executable: any(named: 'executable'),
          arguments: any(named: 'arguments'),
        ),
      ).called(1);
    });

    group('Coverage check failures', () {
      test('fails if coverage is below threshold', () async {
        final options = CiGuardOptions(
          minCoverage: 95,
          coveragePath: 'coverage/lcov.info',
          coverageExclude: const <String>[],
          skipFormat: true,
          skipAnalyze: true,
          skipTests: true,
        );

        when(
          () => mockCoverageChecker.check(
            coveragePath: any(named: 'coveragePath'),
            minimumCoverage: any(named: 'minimumCoverage'),
            excludePatterns: any(named: 'excludePatterns'),
          ),
        ).thenReturn(
          const CoverageCheckResult(
            success: false,
            exitCode: ExitCodes.coverageBelowThreshold,
            summary: CoverageSummary(linesFound: 10, linesHit: 9),
            minimumCoverage: 95,
            excludedFilesCount: 0,
            includedFilesCount: 1,
          ),
        );

        final result = await ciGuard.run(options);

        expect(result.success, isFalse);
        expect(result.exitCode, equals(ExitCodes.coverageBelowThreshold));
        verify(
          () => mockConsole.error(any(that: contains('coverage check failed'))),
        ).called(1);
      });

      test('handles FileSystemException (file not found)', () async {
        final options = CiGuardOptions(
          minCoverage: 80,
          coveragePath: 'missing/lcov.info',
          coverageExclude: const <String>[],
          skipFormat: true,
          skipAnalyze: true,
          skipTests: true,
        );

        when(
          () => mockCoverageChecker.check(
            coveragePath: any(named: 'coveragePath'),
            minimumCoverage: any(named: 'minimumCoverage'),
            excludePatterns: any(named: 'excludePatterns'),
          ),
        ).thenThrow(const FileSystemException('File not found'));

        final result = await ciGuard.run(options);

        expect(result.success, isFalse);
        expect(result.exitCode, equals(ExitCodes.coverageFileNotFound));
        verify(
          () => mockConsole.error(any(that: contains('not found'))),
        ).called(1);
      });

      test('handles LcovParseException', () async {
        final options = CiGuardOptions(
          minCoverage: 80,
          coveragePath: 'invalid/lcov.info',
          coverageExclude: const <String>[],
          skipFormat: true,
          skipAnalyze: true,
          skipTests: true,
        );

        when(
          () => mockCoverageChecker.check(
            coveragePath: any(named: 'coveragePath'),
            minimumCoverage: any(named: 'minimumCoverage'),
            excludePatterns: any(named: 'excludePatterns'),
          ),
        ).thenThrow(const LcovParseException('Invalid format'));

        final result = await ciGuard.run(options);

        expect(result.success, isFalse);
        expect(result.exitCode, equals(ExitCodes.coverageParseError));
        verify(
          () => mockConsole.error(any(that: contains('LcovParseException'))),
        ).called(1);
      });

      test('prints excluded file count when exclusions apply', () async {
        final options = CiGuardOptions(
          minCoverage: 80,
          coveragePath: 'coverage/lcov.info',
          coverageExclude: const <String>['**/*.g.dart'],
          skipFormat: true,
          skipAnalyze: true,
          skipTests: true,
        );

        when(
          () => mockCoverageChecker.check(
            coveragePath: any(named: 'coveragePath'),
            minimumCoverage: any(named: 'minimumCoverage'),
            excludePatterns: any(named: 'excludePatterns'),
          ),
        ).thenReturn(
          const CoverageCheckResult(
            success: true,
            exitCode: 0,
            summary: CoverageSummary(linesFound: 10, linesHit: 9),
            minimumCoverage: 80,
            excludedFilesCount: 2,
            includedFilesCount: 3,
          ),
        );

        final result = await ciGuard.run(options);

        expect(result.success, isTrue);
        verify(
          () => mockConsole.info('Excluded 2 file(s) from coverage'),
        ).called(1);
      });

      test(
        'handles CoverageCheckException when all files are excluded',
        () async {
          final options = CiGuardOptions(
            minCoverage: 80,
            coveragePath: 'coverage/lcov.info',
            coverageExclude: const <String>['**/*.g.dart'],
            skipFormat: true,
            skipAnalyze: true,
            skipTests: true,
          );

          when(
            () => mockCoverageChecker.check(
              coveragePath: any(named: 'coveragePath'),
              minimumCoverage: any(named: 'minimumCoverage'),
              excludePatterns: any(named: 'excludePatterns'),
            ),
          ).thenThrow(
            const CoverageCheckException(
              'All coverage files were excluded from calculation.',
            ),
          );

          final result = await ciGuard.run(options);

          expect(result.success, isFalse);
          expect(result.exitCode, equals(ExitCodes.coverageParseError));
          verify(
            () => mockConsole.error(
              any(that: contains('CoverageCheckException')),
            ),
          ).called(1);
        },
      );
    });
  });
}
