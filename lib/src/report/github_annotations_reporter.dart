import '../cli/options.dart';
import '../core/result.dart';
import '../coverage/file_coverage_record.dart';

/// Emits GitHub Actions workflow command annotations for low-coverage files.
class GitHubAnnotationsReporter {
  /// Creates a [GitHubAnnotationsReporter].
  const GitHubAnnotationsReporter({void Function(String message)? writer})
    : _writer = writer;

  static const int defaultMaxAnnotations = 10;

  final void Function(String message)? _writer;

  /// Writes annotations for low-coverage files when available.
  void reportLowCoverageFiles({
    required CiGuardOptions options,
    required GuardRunResult result,
  }) {
    final List<FileCoverageRecord> lowCoverageFiles =
        result.coverageResult?.lowCoverageFiles ?? const <FileCoverageRecord>[];

    if (lowCoverageFiles.isEmpty) {
      return;
    }

    final int limit = options.showTopLowFiles ?? defaultMaxAnnotations;
    final bool coverageFailed = result.coverageResult?.success == false;
    final int? requiredCoverage =
        options.perFileMinCoverage ??
        (coverageFailed ? options.minCoverage : null);
    final String command = coverageFailed ? 'error' : 'warning';
    final String title = coverageFailed ? 'Coverage failed' : 'Low coverage';

    for (final FileCoverageRecord file in lowCoverageFiles.take(limit)) {
      _write(
        _buildAnnotation(
          command: command,
          filePath: file.path,
          title: title,
          message: _buildMessage(file, requiredCoverage),
        ),
      );
    }
  }

  /// Escapes a GitHub workflow command value or message.
  String escapeWorkflowCommandValue(
    String value, {
    bool escapeMetadata = false,
  }) {
    String escaped = value
        .replaceAll('%', '%25')
        .replaceAll('\r', '%0D')
        .replaceAll('\n', '%0A');

    if (escapeMetadata) {
      escaped = escaped.replaceAll(':', '%3A').replaceAll(',', '%2C');
    }

    return escaped;
  }

  String _buildAnnotation({
    required String command,
    required String filePath,
    required String title,
    required String message,
  }) {
    final String escapedFilePath = escapeWorkflowCommandValue(
      filePath,
      escapeMetadata: true,
    );
    final String escapedTitle = escapeWorkflowCommandValue(
      title,
      escapeMetadata: true,
    );
    final String escapedMessage = escapeWorkflowCommandValue(message);

    return '::$command '
        'file=$escapedFilePath,line=1,title=$escapedTitle'
        '::$escapedMessage';
  }

  String _buildMessage(FileCoverageRecord file, int? requiredCoverage) {
    final String coverage = file.percentage.toStringAsFixed(2);
    if (requiredCoverage == null) {
      return 'Coverage is $coverage%.';
    }

    final String required = requiredCoverage.toStringAsFixed(2);
    return 'Coverage is $coverage%, below required $required%';
  }

  void _write(String message) {
    final void Function(String message)? writer = _writer;
    if (writer != null) {
      writer(message);
    }
  }
}
