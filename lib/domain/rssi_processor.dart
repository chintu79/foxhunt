enum Trend { stronger, weaker, stable }

class RssiProcessor {
  final double alpha; // Smoothing factor (0 < alpha < 1)
  double? _filteredRssi;

  RssiProcessor({this.alpha = 0.3});

  void processSample(int currentRssi) {
    if (_filteredRssi == null) {
      _filteredRssi = currentRssi.toDouble();
    } else {
      _filteredRssi = alpha * currentRssi + (1 - alpha) * _filteredRssi!;
    }
  }

  double? get filteredRssi => _filteredRssi;

  Trend calculateTrend(double previousFiltered) {
    if (_filteredRssi == null) return Trend.stable;
    
    final delta = _filteredRssi! - previousFiltered;
    if (delta > 0.5) return Trend.stronger; // Signal improving (less negative)
    if (delta < -0.5) return Trend.weaker;  // Signal worsening (more negative)
    return Trend.stable;
  }
}
