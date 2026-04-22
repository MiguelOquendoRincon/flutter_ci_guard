import 'package:path/path.dart' as p;

/// Applies glob-based coverage exclusions to file paths.
class CoverageExcluder {
  /// Creates a const [CoverageExcluder].
  const CoverageExcluder();

  /// Returns `true` when [filePath] matches at least one exclusion [patterns].
  ///
  /// Invalid patterns are ignored.
  bool isExcluded(String filePath, Iterable<String> patterns) {
    final String normalizedPath = _normalizePath(filePath);

    for (final String pattern in patterns) {
      final String trimmedPattern = pattern.trim();
      if (trimmedPattern.isEmpty) {
        continue;
      }

      final RegExp? regex = _tryBuildRegex(trimmedPattern);
      if (regex != null && regex.hasMatch(normalizedPath)) {
        return true;
      }
    }

    return false;
  }

  String _normalizePath(String value) {
    return p.posix.normalize(value.replaceAll('\\', '/'));
  }

  RegExp? _tryBuildRegex(String pattern) {
    try {
      final String normalizedPattern = _normalizePath(pattern);
      final StringBuffer buffer = StringBuffer('^');

      for (int index = 0; index < normalizedPattern.length; index++) {
        final String character = normalizedPattern[index];
        final bool nextIsStar =
            index + 1 < normalizedPattern.length &&
            normalizedPattern[index + 1] == '*';

        if (character == '*' && nextIsStar) {
          final bool slashAfterDoubleStar =
              index + 2 < normalizedPattern.length &&
              normalizedPattern[index + 2] == '/';

          buffer.write(slashAfterDoubleStar ? '(?:.*/)?' : '.*');
          index += slashAfterDoubleStar ? 2 : 1;
          continue;
        }

        if (character == '*') {
          buffer.write('[^/]*');
          continue;
        }

        if (character == '?') {
          buffer.write('[^/]');
          continue;
        }

        buffer.write(RegExp.escape(character));
      }

      buffer.write(r'$');
      return RegExp(buffer.toString());
    } on FormatException {
      return null;
    }
  }
}
