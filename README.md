<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# flutter_ci_guard

CI-friendly quality gates for Flutter projects.

`flutter_ci_guard` is a lightweight Dart CLI that enforces quality checks in Flutter CI/CD pipelines.

It runs:

- flutter format
- flutter analyze
- flutter test --coverage

And fails the build if coverage is below the configured threshold.

## Installation

```bash
dart pub global activate flutter_ci_guard