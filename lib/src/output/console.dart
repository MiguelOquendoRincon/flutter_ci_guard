import 'dart:io';

class Console {
  const Console();

  void info(String message) {
    stdout.writeln(message);
  }

  void success(String message) {
    stdout.writeln(message);
  }

  void error(String message) {
    stdout.writeln(message);
  }

  void warning(String message) {
    stdout.writeln(message);
  }

  void section(String title) {
    stdout.writeln('\n==> $title');
  }
}
