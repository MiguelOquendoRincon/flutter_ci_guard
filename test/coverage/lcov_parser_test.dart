import 'package:flutter_ci_guard/src/coverage/lcov_parser.dart';
import 'package:test/test.dart';

void main() {
  group('LcovParser', () {
    const LcovParser parser = LcovParser();

    test('parses covered and uncovered lines correctly', () {
      const String content = '''
TN:
SF:lib/main.dart
DA:1,1
DA:2,0
DA:3,3
end_of_record
''';

      final summary = parser.parse(content);

      expect(summary.linesFound, 3);
      expect(summary.linesHit, 2);
      expect(summary.percentage, closeTo(66.67, 0.01));
    });

    test('returns zero coverage when no DA lines exist', () {
      const String content = '''
TN:
SF:lib/main.dart
LF:0
LH:0
end_of_record
''';

      final summary = parser.parse(content);

      expect(summary.linesFound, 0);
      expect(summary.linesHit, 0);
      expect(summary.percentage, 0);
    });

    test('ignores empty lines and unrelated lcov entries', () {
      const String content = '''

TN:
SF:lib/main.dart
FN:1,main
FNDA:1,main
BRDA:1,0,0,1
DA:10,1
DA:11,0
LF:2
LH:1
end_of_record

''';

      final summary = parser.parse(content);

      expect(summary.linesFound, 2);
      expect(summary.linesHit, 1);
      expect(summary.percentage, 50);
    });

    test('aggregates DA lines across multiple source files', () {
      const String content = '''
TN:
SF:lib/a.dart
DA:1,1
DA:2,0
end_of_record
TN:
SF:lib/b.dart
DA:1,4
DA:2,1
DA:3,0
end_of_record
''';

      final summary = parser.parse(content);

      expect(summary.linesFound, 5);
      expect(summary.linesHit, 3);
      expect(summary.percentage, 60);
    });

    test('builds file-level records from LCOV content', () {
      const String content = '''
TN:
SF:lib/a.dart
DA:1,1
DA:2,0
end_of_record
SF:lib/generated/file.g.dart
DA:1,1
end_of_record
''';

      final records = parser.parseRecords(content);

      expect(records, hasLength(2));
      expect(records[0].path, equals('lib/a.dart'));
      expect(records[0].linesFound, equals(2));
      expect(records[0].linesHit, equals(1));
      expect(records[1].path, equals('lib/generated/file.g.dart'));
      expect(records[1].linesFound, equals(1));
      expect(records[1].linesHit, equals(1));
    });

    test('throws when DA entry has missing execution count', () {
      const String content = '''
SF:lib/main.dart
DA:12
end_of_record
''';

      expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
    });

    test('throws when DA entry has invalid line number', () {
      const String content = '''
SF:lib/main.dart
DA:abc,1
end_of_record
''';

      expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
    });

    test('throws when DA entry has invalid execution count', () {
      const String content = '''
SF:lib/main.dart
DA:12,xyz
end_of_record
''';

      expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
    });

    test('throws when DA entry has negative line number', () {
      const String content = '''
SF:lib/main.dart
DA:-1,1
end_of_record
''';

      expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
    });

    test('throws when DA entry has negative execution count', () {
      const String content = '''
SF:lib/main.dart
DA:8,-1
end_of_record
''';

      expect(() => parser.parse(content), throwsA(isA<LcovParseException>()));
    });
  });
}
