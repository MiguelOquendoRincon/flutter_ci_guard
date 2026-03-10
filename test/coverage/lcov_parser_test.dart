import 'package:flutter_ci_guard/src/coverage/lcov_parser.dart';
import 'package:test/test.dart';

void main() {
  late LcovParser parser;

  setUp(() {
    parser = const LcovParser();
  });

  group('LcovParser', () {
    test('parses simple valid content correctly', () {
      const content = '''
SF:lib/src/sample.dart
DA:1,1
DA:2,0
DA:3,5
end_of_record
''';
      final summary = parser.parse(content);

      expect(summary.linesFound, equals(3));
      expect(summary.linesHit, equals(2));
      expect(summary.percentage, closeTo(66.66, 0.01));
    });

    test('ignores non-DA lines', () {
      const content = '''
TN:
SF:lib/src/sample.dart
FN:1,main
FNDA:1,main
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
''';
      final summary = parser.parse(content);

      expect(summary.linesFound, equals(2));
      expect(summary.linesHit, equals(1));
    });

    test('handles 100% coverage', () {
      const content = '''
DA:1,1
DA:2,10
DA:3,1
''';
      final summary = parser.parse(content);

      expect(summary.linesFound, equals(3));
      expect(summary.linesHit, equals(3));
      expect(summary.percentage, equals(100.0));
    });

    test('handles 0% coverage', () {
      const content = '''
DA:1,0
DA:2,0
''';
      final summary = parser.parse(content);

      expect(summary.linesFound, equals(2));
      expect(summary.linesHit, equals(0));
      expect(summary.percentage, equals(0.0));
    });

    test('handles empty content', () {
      final summary = parser.parse('');

      expect(summary.linesFound, equals(0));
      expect(summary.linesHit, equals(0));
      expect(summary.percentage, equals(0.0));
    });

    test('handles content with only whitespace', () {
      final summary = parser.parse('  \n  \n');

      expect(summary.linesFound, equals(0));
      expect(summary.linesHit, equals(0));
    });

    group('Error handling', () {
      test(
        'throws LcovParseException for invalid DA entry (missing comma)',
        () {
          const content = 'DA:1';
          expect(
            () => parser.parse(content),
            throwsA(isA<LcovParseException>()),
          );
        },
      );

      test('throws LcovParseException for non-numeric line number', () {
        const content = 'DA:abc,1';
        expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
      });

      test('throws LcovParseException for non-numeric execution count', () {
        const content = 'DA:1,abc';
        expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
      });

      test('throws LcovParseException for negative line number', () {
        const content = 'DA:-1,1';
        expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
      });

      test('throws LcovParseException for negative execution count', () {
        const content = 'DA:1,-5';
        expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
      });
    });
  });
}
