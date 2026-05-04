import 'package:flutter_ci_guard/src/coverage/coverage_aggregator.dart';
import 'package:flutter_ci_guard/src/coverage/file_coverage_record.dart';
import 'package:test/test.dart';

void main() {
  const aggregator = CoverageAggregator();

  group('CoverageAggregator.selectLowCoverageFiles', () {
    test('returns empty when no per-file config is provided', () {
      final result = aggregator.selectLowCoverageFiles(const [
        FileCoverageRecord(path: 'lib/a.dart', linesFound: 10, linesHit: 5),
      ]);

      expect(result, isEmpty);
    });

    test('filters by threshold and sorts by percentage then path', () {
      final result = aggregator.selectLowCoverageFiles(const [
        FileCoverageRecord(path: 'lib/b.dart', linesFound: 10, linesHit: 5),
        FileCoverageRecord(path: 'lib/a.dart', linesFound: 10, linesHit: 5),
        FileCoverageRecord(path: 'lib/c.dart', linesFound: 10, linesHit: 6),
        FileCoverageRecord(path: 'lib/d.dart', linesFound: 10, linesHit: 8),
      ], minimumCoverage: 70);

      expect(
        result.map((FileCoverageRecord record) => record.path).toList(),
        equals(const <String>['lib/a.dart', 'lib/b.dart', 'lib/c.dart']),
      );
    });

    test('limits results to the top N lowest-coverage files', () {
      final result = aggregator.selectLowCoverageFiles(const [
        FileCoverageRecord(path: 'lib/a.dart', linesFound: 10, linesHit: 1),
        FileCoverageRecord(path: 'lib/b.dart', linesFound: 10, linesHit: 2),
        FileCoverageRecord(path: 'lib/c.dart', linesFound: 10, linesHit: 3),
      ], topCount: 2);

      expect(
        result.map((FileCoverageRecord record) => record.path).toList(),
        equals(const <String>['lib/a.dart', 'lib/b.dart']),
      );
    });

    test('supports using threshold and top N together', () {
      final result = aggregator.selectLowCoverageFiles(
        const [
          FileCoverageRecord(path: 'lib/a.dart', linesFound: 10, linesHit: 1),
          FileCoverageRecord(path: 'lib/b.dart', linesFound: 10, linesHit: 2),
          FileCoverageRecord(path: 'lib/c.dart', linesFound: 10, linesHit: 9),
        ],
        minimumCoverage: 70,
        topCount: 1,
      );

      expect(result, hasLength(1));
      expect(result.first.path, equals('lib/a.dart'));
    });

    test('ignores files with zero executable lines', () {
      final result = aggregator.selectLowCoverageFiles(const [
        FileCoverageRecord(path: 'lib/a.dart', linesFound: 0, linesHit: 0),
        FileCoverageRecord(path: 'lib/b.dart', linesFound: 10, linesHit: 4),
      ], topCount: 5);

      expect(result, hasLength(1));
      expect(result.single.path, equals('lib/b.dart'));
    });
  });
}
