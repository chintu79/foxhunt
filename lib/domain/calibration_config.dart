import 'package:shared_preferences/shared_preferences.dart';

class CalibrationConfig {
  // RSSI State Entry Thresholds (dBm)
  // Higher dBm = stronger signal (closer)
  // RSSI State Entry Thresholds (dBm)
  // Higher dBm = stronger signal (closer)
  final double coldToWarmThreshold;      // -90.0 dBm
  final double warmToHotThreshold;        // -80.0 dBm
  final double hotToVeryHotThreshold;    // -70.0 dBm
  final double alarmThreshold;            // -65.0 dBm (triggers real/dummy alarm)

  // Hysteresis Margin (dB)
  // Leaving a state requires dropping below (entryThreshold - hysteresisMargin)
  final double hysteresisMargin;          // e.g. 2.5 dB

  // Filter Configuration
  final int medianWindowSize;             // 3 to 9 (odd number recommended)
  final double emaAlpha;                  // 0.05 to 0.95 (smoothing factor)

  // Confirmation Window (Consecutive valid samples required to change state)
  final int confirmationCount;            // e.g. 2 or 3

  // Signal Trend Configuration
  final double trendDeltaThreshold;       // Min dB change to declare improving/worsening (e.g. 4.0 dB)
  final double trendWindowSeconds;        // Comparison time window in seconds (e.g. 5.0 s)
  final int trendBaselineWindow;          // Number of older samples to average for trend baseline

  // Signal Stability Configuration
  final double stabilityStdDevThreshold;  // Max standard deviation in dB to consider signal stable
  final int minSamplesForStability;       // Min samples needed before declaring stable vs insufficient

  // Timeout Thresholds
  final int staleTimeoutMs;               // Ms without target packet to flag stale reading
  final int unavailableTimeoutMs;         // Ms without target packet to declare unavailable
  final String eventPasscode;             // Passcode to unlock the hunt
  final String realTargetName;            // The designated REAL transmitter (e.g. FOXHUNT_01)

  const CalibrationConfig({
    this.coldToWarmThreshold = -90.0,
    this.warmToHotThreshold = -80.0,
    this.hotToVeryHotThreshold = -70.0,
    this.alarmThreshold = -65.0,
    this.hysteresisMargin = 2.5,
    this.medianWindowSize = 5,
    this.emaAlpha = 0.20,
    this.confirmationCount = 1,
    this.trendDeltaThreshold = 4.0,
    this.trendWindowSeconds = 5.0,
    this.trendBaselineWindow = 3,
    this.stabilityStdDevThreshold = 3.5,
    this.minSamplesForStability = 3,
    this.staleTimeoutMs = 3000,
    this.unavailableTimeoutMs = 8000,
    this.eventPasscode = 'FOX2026',
    this.realTargetName = 'FOXHUNT_01',
  });

  bool isRealTarget(String targetName) {
    final normTarget = targetName.trim().toUpperCase().replaceAll('FOXHUNT_0', 'FOXHUNT_');
    final normReal = realTargetName.trim().toUpperCase().replaceAll('FOXHUNT_0', 'FOXHUNT_');
    return normTarget == normReal;
  }

  CalibrationConfig copyWith({
    double? coldToWarmThreshold,
    double? warmToHotThreshold,
    double? hotToVeryHotThreshold,
    double? alarmThreshold,
    double? hysteresisMargin,
    int? medianWindowSize,
    double? emaAlpha,
    int? confirmationCount,
    double? trendDeltaThreshold,
    double? trendWindowSeconds,
    int? trendBaselineWindow,
    double? stabilityStdDevThreshold,
    int? minSamplesForStability,
    int? staleTimeoutMs,
    int? unavailableTimeoutMs,
    String? eventPasscode,
    String? realTargetName,
  }) {
    return CalibrationConfig(
      coldToWarmThreshold: coldToWarmThreshold ?? this.coldToWarmThreshold,
      warmToHotThreshold: warmToHotThreshold ?? this.warmToHotThreshold,
      hotToVeryHotThreshold: hotToVeryHotThreshold ?? this.hotToVeryHotThreshold,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      hysteresisMargin: hysteresisMargin ?? this.hysteresisMargin,
      medianWindowSize: medianWindowSize ?? this.medianWindowSize,
      emaAlpha: emaAlpha ?? this.emaAlpha,
      confirmationCount: confirmationCount ?? this.confirmationCount,
      trendDeltaThreshold: trendDeltaThreshold ?? this.trendDeltaThreshold,
      trendWindowSeconds: trendWindowSeconds ?? this.trendWindowSeconds,
      trendBaselineWindow: trendBaselineWindow ?? this.trendBaselineWindow,
      stabilityStdDevThreshold: stabilityStdDevThreshold ?? this.stabilityStdDevThreshold,
      minSamplesForStability: minSamplesForStability ?? this.minSamplesForStability,
      staleTimeoutMs: staleTimeoutMs ?? this.staleTimeoutMs,
      unavailableTimeoutMs: unavailableTimeoutMs ?? this.unavailableTimeoutMs,
      eventPasscode: eventPasscode ?? this.eventPasscode,
      realTargetName: realTargetName ?? this.realTargetName,
    );
  }

  // Persistence keys
  static const String _keyColdToWarm = 'calib_v7_cold_to_warm';
  static const String _keyWarmToHot = 'calib_v7_warm_to_hot';
  static const String _keyHotToVeryHot = 'calib_v7_hot_to_very_hot';
  static const String _keyAlarmThreshold = 'calib_v7_alarm_threshold';
  static const String _keyHysteresis = 'calib_v7_hysteresis';
  static const String _keyMedianWindow = 'calib_v7_median_window';
  static const String _keyEmaAlpha = 'calib_v7_ema_alpha';
  static const String _keyConfirmation = 'calib_confirmation_count';
  static const String _keyTrendDelta = 'calib_trend_delta';
  static const String _keyTrendWindow = 'calib_trend_window_sec';
  static const String _keyStabilityStdDev = 'calib_stability_std_dev';
  static const String _keyEventPasscode = 'calib_event_passcode';
  static const String _keyRealTargetName = 'calib_real_target_name';
  static const String _keyStaleTimeout = 'calib_stale_timeout_ms';
  static const String _keyUnavailableTimeout = 'calib_unavailable_timeout_ms';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyColdToWarm, coldToWarmThreshold);
    await prefs.setDouble(_keyWarmToHot, warmToHotThreshold);
    await prefs.setDouble(_keyHotToVeryHot, hotToVeryHotThreshold);
    await prefs.setDouble(_keyAlarmThreshold, alarmThreshold);
    await prefs.setDouble(_keyHysteresis, hysteresisMargin);
    await prefs.setInt(_keyMedianWindow, medianWindowSize);
    await prefs.setDouble(_keyEmaAlpha, emaAlpha);
    await prefs.setInt(_keyConfirmation, confirmationCount);
    await prefs.setDouble(_keyTrendDelta, trendDeltaThreshold);
    await prefs.setDouble(_keyTrendWindow, trendWindowSeconds);
    await prefs.setDouble(_keyStabilityStdDev, stabilityStdDevThreshold);
    await prefs.setString(_keyEventPasscode, eventPasscode);
    await prefs.setString(_keyRealTargetName, realTargetName);
    await prefs.setInt(_keyStaleTimeout, staleTimeoutMs);
    await prefs.setInt(_keyUnavailableTimeout, unavailableTimeoutMs);
  }

  static Future<CalibrationConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return CalibrationConfig(
      coldToWarmThreshold: prefs.getDouble(_keyColdToWarm) ?? -90.0,
      warmToHotThreshold: prefs.getDouble(_keyWarmToHot) ?? -80.0,
      hotToVeryHotThreshold: prefs.getDouble(_keyHotToVeryHot) ?? -70.0,
      alarmThreshold: prefs.getDouble(_keyAlarmThreshold) ?? -65.0,
      hysteresisMargin: prefs.getDouble(_keyHysteresis) ?? 2.5,
      medianWindowSize: prefs.getInt(_keyMedianWindow) ?? 5,
      emaAlpha: prefs.getDouble(_keyEmaAlpha) ?? 0.20,
      confirmationCount: prefs.getInt(_keyConfirmation) ?? 1,
      trendDeltaThreshold: prefs.getDouble(_keyTrendDelta) ?? 4.0,
      trendWindowSeconds: prefs.getDouble(_keyTrendWindow) ?? 5.0,
      stabilityStdDevThreshold: prefs.getDouble(_keyStabilityStdDev) ?? 3.5,
      eventPasscode: prefs.getString(_keyEventPasscode) ?? 'FOX2026',
      realTargetName: prefs.getString(_keyRealTargetName) ?? 'FOXHUNT_01',
      staleTimeoutMs: prefs.getInt(_keyStaleTimeout) ?? 3000,
      unavailableTimeoutMs: prefs.getInt(_keyUnavailableTimeout) ?? 8000,
    );
  }

  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyColdToWarm);
    await prefs.remove(_keyWarmToHot);
    await prefs.remove(_keyHotToVeryHot);
    await prefs.remove(_keyHysteresis);
    await prefs.remove(_keyMedianWindow);
    await prefs.remove(_keyEmaAlpha);
    await prefs.remove(_keyConfirmation);
    await prefs.remove(_keyTrendDelta);
    await prefs.remove(_keyTrendWindow);
    await prefs.remove(_keyStabilityStdDev);
    await prefs.remove(_keyEventPasscode);
    await prefs.remove(_keyRealTargetName);
    await prefs.remove(_keyStaleTimeout);
    await prefs.remove(_keyUnavailableTimeout);
  }
}
