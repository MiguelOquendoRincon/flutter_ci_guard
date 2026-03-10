import 'dart:io';

/// Writes formatted output to stdout.
///
/// [Console] is a thin wrapper around [stdout] that categorises output into
/// logical message types. Using a class (rather than top-level functions)
/// makes it possible to inject a mock in unit tests without capturing real
/// stdout.
class Console {
  /// Creates a const [Console].
  const Console();

  /// Writes an informational [message] to stdout.
  void info(String message) {
    stdout.writeln(message);
  }

  /// Writes a success [message] to stdout.
  void success(String message) {
    stdout.writeln(message);
  }

  /// Writes an error [message] to stdout.
  ///
  /// Note: the message is intentionally written to stdout (not stderr) so
  /// that CI log streams remain in order and easy to read.
  void error(String message) {
    stdout.writeln(message);
  }

  /// Writes a warning [message] to stdout.
  void warning(String message) {
    stdout.writeln(message);
  }

  /// Writes a section header [title] to stdout, visually separated from
  /// surrounding output by a `==>` prefix and leading blank line.
  void section(String title) {
    stdout.writeln('\n==> $title');
  }
}
