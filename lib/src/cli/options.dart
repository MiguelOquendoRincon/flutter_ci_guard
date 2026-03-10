class CiGuardOptions {
  final int minCoverage;
  final String coveragePath;
  final bool skipFormat;
  final bool skipAnalyze;
  final bool skipTests;

  CiGuardOptions({
    required this.minCoverage,
    required this.coveragePath,
    required this.skipFormat,
    required this.skipAnalyze,
    required this.skipTests,
  });
}
