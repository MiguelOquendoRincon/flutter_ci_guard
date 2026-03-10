# Changelog

## 0.0.1

Initial release of `flutter_ci_guard` - a lightweight CLI tool to enforce quality gates in Flutter projects.

### Features
- **CI Orchestration**: Run format, analyze, and tests in a single command.
- **Coverage Enforcement**: Automatically parse LCOV files and fail if the threshold is not met.
- **Fail-Fast**: Stop execution immediately if any quality gate fails.
- **Customizable**: Skip specific steps (format, analyze, or tests) as needed.
- **CI-Ready**: Returns specific exit codes for different failure types (low coverage, missing files, parse errors).
- **Zero-Dependency Core**: Only relies on official Dart packages (`args` and `path`).