# 🛡️ flutter_ci_guard

[![pub package](https://img.shields.io/pub/v/flutter_ci_guard.svg)](https://pub.dev/packages/flutter_ci_guard)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Stop technical debt before it reaches production. `flutter_ci_guard` is a lightweight, zero-dependency CLI tool designed to be the final gatekeeper in your Flutter CI/CD pipelines.

## 🚀 What does it solve?

CIs often have separate steps for formatting, linting, and testing. If one fails, you might get scattered reports. More importantly, **enforcing a minimum coverage percentage** usually requires complex shell scripts or heavy third-party services.

`flutter_ci_guard` orchestrates these "Quality Gates" into a single, reliable command that:
1. 🧹 **Ensures code is formatted** (fails if `dart format` finds changes).
2. 🔍 **Runs static analysis** (fails if `flutter analyze` finds issues).
3. 🧪 **Executes tests with coverage** (fails if tests fail).
4. 📈 **Enforces coverage thresholds** (fails if coverage is below your limit).

---

## 📦 Installation

Add it as a dev dependency in your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_ci_guard: latest_version
```

Or install it globally:

```bash
dart pub global activate flutter_ci_guard
```

---

## 🛠️ Basic Usage

Run it from the root of your Flutter project:

```bash
# Runs everything with default 80% coverage threshold
dart run flutter_ci_guard
```

### Real-world examples

**Enforce strict 95% coverage:**
```bash
dart run flutter_ci_guard --min-coverage 95
```

**Check only analysis and coverage (skipping format and tests runtime):**
```bash
# Useful if you already ran tests in a previous CI step but need to check the LCOV file
dart run flutter_ci_guard --skip-format --skip-tests --min-coverage 80
```

### Configuration file

You can store defaults in a `flutter_ci_guard.yaml` file at your project root.

```yaml
steps:
  format: true
  analyze: true
  test: true

coverage:
  min: 85
  path: coverage/lcov.info
```

`flutter_ci_guard` loads this file automatically when present. You can also point to a custom file:

```bash
dart run flutter_ci_guard --config ci/flutter_ci_guard.yaml
```

Precedence is:

`CLI flags > YAML config > built-in defaults`

---

## ⚙️ Configuration Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--config` | auto-detect `flutter_ci_guard.yaml` | Path to a YAML config file. |
| `--min-coverage` | `80` | Required percentage (0-100). |
| `--coverage-path` | `coverage/lcov.info` | Path to the generated LCOV file. |
| `--skip-format` | `false` | Skip `dart format` validation. |
| `--skip-analyze` | `false` | Skip `flutter analyze`. |
| `--skip-tests` | `false` | Skip `flutter test --coverage`. |
| `--help` | - | Show usage information. |

---

## 🤖 CI/CD Integration

### GitHub Actions
The most common way to use `flutter_ci_guard` is as a single "Quality Gate" step.

```yaml
jobs:
  check-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Install dependencies
        run: flutter pub get

      - name: Run Quality Gates
        run: dart run flutter_ci_guard --min-coverage 90
```

---

## 🚪 Exit Behavior

`flutter_ci_guard` returns specific exit codes so your CI can react accordingly:

| Code | Meaning |
|------|---------|
| **0** | **Success** (All gates passed). |
| **1** | **Step Failed** (Format, Analyze, or Tests failed). |
| **2** | **Low Coverage** (Coverage is below the threshold). |
| **3** | **Missing File** (Coverage file not found at the specified path). |
| **4** | **Parse Error** (The LCOV file is malformed). |
| **64** | **Invalid Args** (Wrong CLI usage). |

---

## 🎯 Scope & Philosophy

- **Lightweight**: Minimal dependencies, fast startup.
- **Fail Fast**: If formatting fails, it doesn't waste time running tests.
- **CI-First**: Designed to be the standard way to run checks in pipelines.
- **Pure Dart**: No need for `lcov` or `genhtml` installed on the CI machine to check the percentage.

---

## 👨‍💻 Created & Maintained By

**Miguel Angel Oquendo Rincon**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/miguel-angel-oquendo-rincon)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MiguelOquendoRincon)

---

## 📄 License
MIT License - see [LICENSE](LICENSE) for details.
