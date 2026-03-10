import 'package:flutter_ci_guard/src/coverage/coverage_summary.dart';
import 'package:test/test.dart';

void main() {
  group('CoverageSummary', () {
    test('calculates percentage correctly', () {
      const summary = CoverageSummary(linesFound: 100, linesHit: 75);
      expect(summary.percentage, equals(75.0));
    });

    test('handles zero lines found by returning 0.0', () {
      const summary = CoverageSummary(linesFound: 0, linesHit: 0);
      expect(summary.percentage, equals(0.0));
    });

    test('handles rounding (if any, though it returns double)', () {
      const summary = CoverageSummary(linesFound: 3, linesHit: 1);
      expect(summary.percentage, closeTo(33.33, 0.01));
    });

    test('handles 100% coverage', () {
      const summary = CoverageSummary(linesFound: 10, linesHit: 10);
      expect(summary.percentage, equals(100.0));
    });
  });
}
