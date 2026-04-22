import 'dart:io';

import 'package:flutter_ci_guard/src/core/exit_codes.dart';
import 'package:flutter_ci_guard/src/coverage/coverage_checker.dart';
import 'package:flutter_ci_guard/src/coverage/file_coverage_record.dart';
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

      when(() => mockParser.parseRecords(any())).thenReturn(const [
        FileCoverageRecord(
          path: 'lib/main.dart',
          linesFound: 100,
          linesHit: 90,
        ),
      ]);

      final result = checker.check(
        coveragePath: coveragePath,
        minimumCoverage: 80,
      );

      expect(result.success, isTrue);
      expect(result.exitCode, equals(ExitCodes.success));
      expect(result.summary.percentage, equals(90.0));
      expect(result.minimumCoverage, equals(80));
      expect(result.excludedFilesCount, equals(0));
      expect(result.includedFilesCount, equals(1));
    });

    test('returns failure when coverage is below threshold', () {
      File(coveragePath).writeAsStringSync('dummy content');

      when(() => mockParser.parseRecords(any())).thenReturn(const [
        FileCoverageRecord(
          path: 'lib/main.dart',
          linesFound: 100,
          linesHit: 70,
        ),
      ]);

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

      when(() => mockParser.parseRecords(any())).thenReturn(const [
        FileCoverageRecord(
          path: 'lib/main.dart',
          linesFound: 100,
          linesHit: 80,
        ),
      ]);

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
        () => mockParser.parseRecords(any()),
      ).thenThrow(const LcovParseException('test error'));

      expect(
        () => checker.check(coveragePath: coveragePath, minimumCoverage: 80),
        throwsA(isA<LcovParseException>()),
      );
    });

    test('keeps coverage identical when no exclusions are provided', () {
      File(coveragePath).writeAsStringSync('''
SF:lib/a.dart
DA:1,1
DA:2,0
end_of_record
SF:lib/b.dart
DA:1,1
DA:2,1
end_of_record
''');

      final realChecker = CoverageChecker(parser: const LcovParser());

      final result = realChecker.check(
        coveragePath: coveragePath,
        minimumCoverage: 70,
      );

      expect(result.summary.linesFound, equals(4));
      expect(result.summary.linesHit, equals(3));
      expect(result.excludedFilesCount, equals(0));
      expect(result.includedFilesCount, equals(2));
    });

    test('excludes one file and recalculates coverage', () {
      File(coveragePath).writeAsStringSync('''
SF:lib/a.dart
DA:1,1
DA:2,0
end_of_record
SF:lib/a.g.dart
DA:1,0
DA:2,0
end_of_record
''');

      final realChecker = CoverageChecker(parser: const LcovParser());

      final result = realChecker.check(
        coveragePath: coveragePath,
        minimumCoverage: 40,
        excludePatterns: const <String>['**/*.g.dart'],
      );

      expect(result.summary.linesFound, equals(2));
      expect(result.summary.linesHit, equals(1));
      expect(result.summary.percentage, equals(50.0));
      expect(result.excludedFilesCount, equals(1));
    });

    test('supports multiple exclusion patterns and nested paths', () {
      File(coveragePath).writeAsStringSync('''
SF:lib/src/feature.dart
DA:1,1
DA:2,0
end_of_record
SF:lib/src/feature.freezed.dart
DA:1,0
DA:2,0
end_of_record
SF:lib/generated/helper.dart
DA:1,0
DA:2,0
end_of_record
''');

      final realChecker = CoverageChecker(parser: const LcovParser());

      final result = realChecker.check(
        coveragePath: coveragePath,
        minimumCoverage: 40,
        excludePatterns: const <String>['**/*.freezed.dart', '**/generated/**'],
      );

      expect(result.summary.linesFound, equals(2));
      expect(result.summary.linesHit, equals(1));
      expect(result.excludedFilesCount, equals(2));
      expect(result.includedFilesCount, equals(1));
    });

    test('matches Windows-style paths when excluding files', () {
      File(coveragePath).writeAsStringSync(r'''
SF:lib\src\feature.dart
DA:1,1
DA:2,0
end_of_record
SF:lib\generated\helper.dart
DA:1,0
DA:2,0
end_of_record
''');

      final realChecker = CoverageChecker(parser: const LcovParser());

      final result = realChecker.check(
        coveragePath: coveragePath,
        minimumCoverage: 40,
        excludePatterns: const <String>['**/generated/**'],
      );

      expect(result.summary.linesFound, equals(2));
      expect(result.summary.linesHit, equals(1));
      expect(result.excludedFilesCount, equals(1));
    });

    test('throws a clear error when all files are excluded', () {
      File(coveragePath).writeAsStringSync('''
SF:lib/generated/helper.g.dart
DA:1,0
DA:2,0
end_of_record
''');

      final realChecker = CoverageChecker(parser: const LcovParser());

      expect(
        () => realChecker.check(
          coveragePath: coveragePath,
          minimumCoverage: 40,
          excludePatterns: const <String>['**/*.g.dart'],
        ),
        throwsA(isA<CoverageCheckException>()),
      );
    });
  });
}
