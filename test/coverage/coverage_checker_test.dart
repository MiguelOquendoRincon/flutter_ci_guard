import 'dart:io';

import 'package:flutter_ci_guard/src/core/exit_codes.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_checker.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_summary.dart';
import 'package:flutter_ci_guard/src/coverage/lcov_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLcovParser extends Mock implements LcovParser {}

void main() {
  late CoverageChecker checker;
  late MockLcovParser mockParser;
  late Directory tempDir;
  late String coveragePath;

  setUp(() {
    mockParser = MockLcovParser();
    checker = CoverageChecker(parser: mockParser);
    tempDir = Directory.systemTemp.createTempSync('coverage_checker_test');
    coveragePath = '${tempDir.path}/lcov.info';
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CoverageChecker', () {
    test('returns success when coverage is above threshold', () {
      File(coveragePath).writeAsStringSync('dummy content');

      when(
        () => mockParser.parse(any()),
      ).thenReturn(const CoverageSummary(linesFound: 100, linesHit: 90));

      final result = checker.check(
        coveragePath: coveragePath,
        minimumCoverage: 80,
      );

      expect(result.success, isTrue);
      expect(result.exitCode, equals(ExitCodes.success));
      expect(result.summary.percentage, equals(90.0));
      expect(result.minimumCoverage, equals(80));
    });

    test('returns failure when coverage is below threshold', () {
      File(coveragePath).writeAsStringSync('dummy content');

      when(
        () => mockParser.parse(any()),
      ).thenReturn(const CoverageSummary(linesFound: 100, linesHit: 70));

      final result = checker.check(
        coveragePath: coveragePath,
        minimumCoverage: 80,
      );

      expect(result.success, isFalse);
      expect(result.exitCode, equals(ExitCodes.coverageBelowThreshold));
      expect(result.summary.percentage, equals(70.0));
    });

    test('returns success when coverage is exactly at threshold', () {
      File(coveragePath).writeAsStringSync('dummy content');

      when(
        () => mockParser.parse(any()),
      ).thenReturn(const CoverageSummary(linesFound: 100, linesHit: 80));

      final result = checker.check(
        coveragePath: coveragePath,
        minimumCoverage: 80,
      );

      expect(result.success, isTrue);
      expect(result.exitCode, equals(ExitCodes.success));
    });

    test('throws FileSystemException when file does not exist', () {
      expect(
        () => checker.check(
          coveragePath: 'non_existent.info',
          minimumCoverage: 80,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('passes exceptions from parser', () {
      File(coveragePath).writeAsStringSync('invalid content');

      when(
        () => mockParser.parse(any()),
      ).thenThrow(const LcovParseException('test error'));

      expect(
        () => checker.check(coveragePath: coveragePath, minimumCoverage: 80),
        throwsA(isA<LcovParseException>()),
      );
    });
  });
}
