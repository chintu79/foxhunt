import 'calibration_config.dart';
import 'rssi_processor.dart';

enum HuntingState {
  cold,
  warm,
  hot,
  veryHot,
}

class SignalStateEngine {
  CalibrationConfig config;

  HuntingState _currentState = HuntingState.cold;
  HuntingState? _pendingState;
  int _pendingConfirmationCount = 0;

  SignalStateEngine({CalibrationConfig? config})
      : config = config ?? const CalibrationConfig();

  void updateConfig(CalibrationConfig newConfig) {
    config = newConfig;
  }

  HuntingState get currentState => _currentState;
  HuntingState? get pendingState => _pendingState;
  int get pendingConfirmationCount => _pendingConfirmationCount;

  /// Evaluates smoothed RSSI and stability to update hunting state with hysteresis
  /// and confirmation window debouncing.
  HuntingState processSample(double smoothedRssi, {SignalStability stability = SignalStability.stable}) {
    final candidateState = _evaluateCandidateState(smoothedRssi);

    // Section 6: Guard against declaring Hot or Very Hot off fluctuating / single spike readings
    if ((candidateState == HuntingState.hot || candidateState == HuntingState.veryHot) &&
        stability == SignalStability.fluctuating) {
      // Hold back transition to Hot/Very Hot if signal is currently fluctuating
      _pendingState = null;
      _pendingConfirmationCount = 0;
      return _currentState;
    }

    if (candidateState != _currentState) {
      if (_pendingState == candidateState) {
        _pendingConfirmationCount++;
      } else {
        _pendingState = candidateState;
        _pendingConfirmationCount = 1;
      }

      // If required confirmation threshold met, confirm transition
      if (_pendingConfirmationCount >= config.confirmationCount) {
        _currentState = candidateState;
        _pendingState = null;
        _pendingConfirmationCount = 0;
      }
    } else {
      // Stable in current state
      _pendingState = null;
      _pendingConfirmationCount = 0;
    }

    return _currentState;
  }

  /// Calculates candidate state based on entry thresholds and hysteresis exit margins.
  HuntingState _evaluateCandidateState(double rssi) {
    switch (_currentState) {
      case HuntingState.cold:
        if (rssi >= config.hotToVeryHotThreshold) return HuntingState.veryHot;
        if (rssi >= config.warmToHotThreshold) return HuntingState.hot;
        if (rssi >= config.coldToWarmThreshold) return HuntingState.warm;
        return HuntingState.cold;

      case HuntingState.warm:
        // Check for promotion
        if (rssi >= config.hotToVeryHotThreshold) return HuntingState.veryHot;
        if (rssi >= config.warmToHotThreshold) return HuntingState.hot;
        // Check for demotion (stricter exit threshold due to hysteresis)
        if (rssi < (config.coldToWarmThreshold - config.hysteresisMargin)) {
          return HuntingState.cold;
        }
        return HuntingState.warm;

      case HuntingState.hot:
        // Check for promotion
        if (rssi >= config.hotToVeryHotThreshold) return HuntingState.veryHot;
        // Check for demotion (stricter exit threshold)
        if (rssi < (config.warmToHotThreshold - config.hysteresisMargin)) {
          // If severely dropped, could fall all the way to cold
          if (rssi < (config.coldToWarmThreshold - config.hysteresisMargin)) {
            return HuntingState.cold;
          }
          return HuntingState.warm;
        }
        return HuntingState.hot;

      case HuntingState.veryHot:
        // Check for demotion (stricter exit threshold)
        if (rssi < (config.hotToVeryHotThreshold - config.hysteresisMargin)) {
          if (rssi < (config.warmToHotThreshold - config.hysteresisMargin)) {
            if (rssi < (config.coldToWarmThreshold - config.hysteresisMargin)) {
              return HuntingState.cold;
            }
            return HuntingState.warm;
          }
          return HuntingState.hot;
        }
        return HuntingState.veryHot;
    }
  }

  String getDisplayMessage(HuntingState state) {
    switch (state) {
      case HuntingState.cold:
        return 'Weak signal. Keep exploring the search area.';
      case HuntingState.warm:
        return 'Moderate signal. Sustained improvement detected.';
      case HuntingState.hot:
        return 'Strong, consistent signal. You are getting close.';
      case HuntingState.veryHot:
        return 'Exceptionally strong signal! Transmitter is in target range.';
    }
  }

  String getStateName(HuntingState state) {
    switch (state) {
      case HuntingState.cold:
        return 'COLD';
      case HuntingState.warm:
        return 'WARM';
      case HuntingState.hot:
        return 'HOT';
      case HuntingState.veryHot:
        return 'VERY HOT';
    }
  }

  void reset() {
    _currentState = HuntingState.cold;
    _pendingState = null;
    _pendingConfirmationCount = 0;
  }
}
