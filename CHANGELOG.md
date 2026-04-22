# Changelog

## 0.2.0

Add coverage exclusion support for `flutter_ci_guard`.

### Added
- Support `coverage.exclude` in `flutter_ci_guard.yaml` using glob-style patterns such as `**/*.g.dart` and `**/generated/**`.
- Support `--coverage-exclude` for passing comma-separated exclusion patterns from the CLI.

### Changed
- Parse LCOV coverage by file record internally before computing the global coverage summary.
- Filter excluded files before aggregation so generated files do not affect the final percentage.

### Notes
- When no exclusions are configured, coverage behavior remains backward compatible with previous releases.

## 0.1.0

Add YAML configuration file support for `flutter_ci_guard`.

### Added
- Auto-load `flutter_ci_guard.yaml` from the project root when present.
- Support `--config <path>` to load a config file from a custom location.
- Merge settings with precedence `CLI > YAML > defaults`.

### Notes
- Existing CLI flags remain backward compatible and continue to work as before.
- Supported YAML keys in this release are `steps.format`, `steps.analyze`, `steps.test`, `coverage.min`, and `coverage.path`.

## 0.0.2

Initial release of `flutter_ci_guard` - a lightweight CLI tool to enforce quality gates in Flutter projects.

### Features
- **CI Orchestration**: Run format, analyze, and tests in a single command.
- **Coverage Enforcement**: Automatically parse LCOV files and fail if the threshold is not met.
- **Fail-Fast**: Stop execution immediately if any quality gate fails.
- **Customizable**: Skip specific steps (format, analyze, or tests) as needed.
- **CI-Ready**: Returns specific exit codes for different failure types (low coverage, missing files, parse errors).
- **Zero-Dependency Core**: Only relies on official Dart packages (`args` and `path`).
