import 'dart:math';
import 'calibration_config.dart';

enum SignalTrend { improving, stable, worsening }

enum SignalStability { stable, fluctuating, insufficientReadings }

class TimestampedRssi {
  final DateTime timestamp;
  final double rssi;

  const TimestampedRssi({required this.timestamp, required this.rssi});
}

class RssiProcessor {
  CalibrationConfig config;

  final List<int> _rawWindow = [];
  final List<TimestampedRssi> _smoothedHistory = [];
  
  double? _filteredRssi;
  int? _lastRawRssi;
  double? _lastMedianRssi;
  DateTime? _lastSampleTime;

  RssiProcessor({CalibrationConfig? config}) 
      : config = config ?? const CalibrationConfig();

  void updateConfig(CalibrationConfig newConfig) {
    config = newConfig;
    while (_rawWindow.length > config.medianWindowSize) {
      _rawWindow.removeAt(0);
    }
  }

  /// Ingests a new raw RSSI reading with optional timestamp.
  /// Validates range [-120, 0] dBm and discards duplicates or physically invalid values.
  /// Reinitializes filter if a substantial interruption occurred (> staleTimeout).
  void processSample(int rawRssi, [DateTime? timestamp]) {
    // 1. Input Validation: Physical range check
    if (rawRssi > 0 || rawRssi < -120) {
      return; // Discard physically invalid or corrupted hardware readings
    }

    final now = timestamp ?? DateTime.now();

    // Deduplicate identical readings arriving with the same explicit timestamp
    if (timestamp != null &&
        _lastSampleTime != null && 
        timestamp.difference(_lastSampleTime!).inMilliseconds == 0 && 
        _lastRawRssi == rawRssi) {
      return;
    }

    // 2. Interruption handling: only reset filter if gap exceeds unavailable threshold
    if (_lastSampleTime != null && 
        now.difference(_lastSampleTime!).inMilliseconds > config.unavailableTimeoutMs) {
      _rawWindow.clear();
      _filteredRssi = null; // Reinitialize EMA when signal was genuinely lost
    }

    _lastRawRssi = rawRssi;
    _lastSampleTime = now;

    // 3. Sliding Raw Window for Median Filtering
    _rawWindow.add(rawRssi);
    if (_rawWindow.length > config.medianWindowSize) {
      _rawWindow.removeAt(0);
    }

    // 4. Compute Median
    final median = _computeMedian(_rawWindow);
    _lastMedianRssi = median;

    // 5. Exponential Moving Average (EMA) on top of Median
    if (_filteredRssi == null) {
      _filteredRssi = median;
    } else {
      _filteredRssi = (config.emaAlpha * median) + ((1.0 - config.emaAlpha) * _filteredRssi!);
    }

    // 6. Record timestamped smoothed history for time-aware trend analysis
    _smoothedHistory.add(TimestampedRssi(timestamp: now, rssi: _filteredRssi!));

    // Keep history within reasonable boundary (up to 3x the trend window)
    final cutoff = now.subtract(Duration(seconds: (config.trendWindowSeconds * 3).round()));
    _smoothedHistory.removeWhere((entry) => entry.timestamp.isBefore(cutoff));
  }

  double _computeMedian(List<int> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<int>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle].toDouble();
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  double? get filteredRssi => _filteredRssi;
  int? get lastRawRssi => _lastRawRssi;
  double? get lastMedianRssi => _lastMedianRssi;
  int get sampleCount => _rawWindow.length;
  DateTime? get lastSampleTime => _lastSampleTime;

  /// Evaluates signal trend: Improving, Stable, or Worsening.
  /// Compares current smoothed reading against an earlier comparison window (~5s),
  /// applying a configurable minimum meaningful change threshold (~4.0 dB) with deadband.
  SignalTrend calculateTrend([DateTime? evalTime]) {
    if (_smoothedHistory.length < 2 || _filteredRssi == null) {
      return SignalTrend.stable;
    }

    final now = evalTime ?? _lastSampleTime ?? DateTime.now();
    final totalSpanMs = _smoothedHistory.last.timestamp.difference(_smoothedHistory.first.timestamp).inMilliseconds;

    // If history has time progression (normal operation):
    if (totalSpanMs > 1000) {
      final targetPastTime = now.subtract(Duration(seconds: config.trendWindowSeconds.round()));

      // Find candidates around target comparison time
      final candidates = _smoothedHistory.where((entry) {
        final diff = entry.timestamp.difference(targetPastTime).inMilliseconds.abs();
        return diff <= 1500;
      }).toList();

      double baselineAvg;
      if (candidates.isNotEmpty) {
        baselineAvg = candidates.map((e) => e.rssi).reduce((a, b) => a + b) / candidates.length;
      } else {
        // Fallback to oldest entry within span
        baselineAvg = _smoothedHistory.first.rssi;
      }

      final delta = _filteredRssi! - baselineAvg;
      if (delta >= config.trendDeltaThreshold) return SignalTrend.improving;
      if (delta <= -config.trendDeltaThreshold) return SignalTrend.worsening;
      return SignalTrend.stable;
    }

    // Sample-based fallback (for rapid unit tests or synthetic samples without clock advance)
    final int window = config.trendBaselineWindow;
    if (_smoothedHistory.length <= window) {
      final delta = _filteredRssi! - _smoothedHistory.first.rssi;
      if (delta >= config.trendDeltaThreshold) return SignalTrend.improving;
      if (delta <= -config.trendDeltaThreshold) return SignalTrend.worsening;
      return SignalTrend.stable;
    }

    // Compare against the window of samples just prior to the latest reading(s)
    final int startIdx = max(0, _smoothedHistory.length - 1 - window);
    final baselineSamples = _smoothedHistory.sublist(startIdx, _smoothedHistory.length - 1);
    final baselineAvg = baselineSamples.map((e) => e.rssi).reduce((a, b) => a + b) / baselineSamples.length;
    final delta = _filteredRssi! - baselineAvg;

    if (delta >= config.trendDeltaThreshold) return SignalTrend.improving;
    if (delta <= -config.trendDeltaThreshold) return SignalTrend.worsening;
    return SignalTrend.stable;
  }

  /// Calculates sample standard deviation of raw readings in the rolling window.
  double calculateStandardDeviation() {
    if (_rawWindow.length < 2) return 0.0;
    final mean = _rawWindow.reduce((a, b) => a + b) / _rawWindow.length;
    final sumSquaredDiffs = _rawWindow
        .map((x) => pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b);
    return sqrt(sumSquaredDiffs / (_rawWindow.length - 1));
  }

  /// Classifies signal stability based on sample variability and valid sample count.
  SignalStability calculateStability() {
    if (_rawWindow.length < config.minSamplesForStability) {
      return SignalStability.insufficientReadings;
    }

    final stdDev = calculateStandardDeviation();
    if (stdDev <= config.stabilityStdDevThreshold) {
      return SignalStability.stable;
    } else {
      return SignalStability.fluctuating;
    }
  }

  void reset() {
    _rawWindow.clear();
    _smoothedHistory.clear();
    _filteredRssi = null;
    _lastRawRssi = null;
    _lastMedianRssi = null;
    _lastSampleTime = null;
  }
}
