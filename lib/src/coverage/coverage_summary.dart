class CoverageSummary {
  const CoverageSummary({required this.linesFound, required this.linesHit});

  final int linesFound;
  final int linesHit;

  double get percentage {
    if (linesFound == 0) {
      return 0;
    }

    return (linesHit / linesFound) * 100;
  }
}
