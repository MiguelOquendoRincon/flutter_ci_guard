import 'dart:io';
import 'package:flutter_ci_guard/flutter_ci_guard.dart';

Future<void> main(List<String> args) async {
  final int exitCodeValue = await runFlutterCiGuard(args);
  exit(exitCodeValue);
}
