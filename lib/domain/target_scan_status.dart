enum TargetScanStatus {
  searching,                  // No matching target detected yet
  targetDetected,             // Live, fresh reading available
  measuring,                  // Insufficient samples to classify reliably
  signalFluctuating,          // Recent measurements are inconsistent
  staleReading,               // Missed in recent sweep; last reading retained with age
  temporarilyUnavailable,     // Consecutive timeouts without detection
  bluetoothDisabled,          // Bluetooth adapter is turned off
  permissionRequired,         // Location or Bluetooth permissions missing
  scanningError,              // BLE scanner encountered an error
  scanningUnavailable,        // Generic scanning unavailable fallback
}

class TargetStatusTracker {
  final int staleTimeoutMs;
  final int unavailableTimeoutMs;

  DateTime? lastSeenTimestamp;
  bool isBluetoothEnabled;
  bool hasPermission;
  bool hasScanningError;
  bool hasEverDetected;

  TargetStatusTracker({
    this.staleTimeoutMs = 3000,
    this.unavailableTimeoutMs = 8000,
    this.isBluetoothEnabled = true,
    this.hasPermission = true,
    this.hasScanningError = false,
    this.hasEverDetected = false,
  });

  void recordTargetSeen([DateTime? timestamp]) {
    lastSeenTimestamp = timestamp ?? DateTime.now();
    hasEverDetected = true;
  }

  void updateBluetoothStatus(bool enabled) {
    isBluetoothEnabled = enabled;
  }

  void updatePermissionStatus(bool granted) {
    hasPermission = granted;
  }

  void updateErrorStatus(bool error) {
    hasScanningError = error;
  }

  TargetScanStatus evaluateStatus({
    DateTime? now,
    int validSampleCount = 0,
    bool isFluctuating = false,
  }) {
    if (!hasPermission) {
      return TargetScanStatus.permissionRequired;
    }
    if (!isBluetoothEnabled) {
      return TargetScanStatus.bluetoothDisabled;
    }
    if (hasScanningError) {
      return TargetScanStatus.scanningError;
    }

    if (!hasEverDetected || lastSeenTimestamp == null) {
      return TargetScanStatus.searching;
    }

    final current = now ?? DateTime.now();
    final elapsedMs = current.difference(lastSeenTimestamp!).inMilliseconds;

    if (elapsedMs < staleTimeoutMs) {
      if (validSampleCount < 3) {
        return TargetScanStatus.measuring;
      }
      if (isFluctuating) {
        return TargetScanStatus.signalFluctuating;
      }
      return TargetScanStatus.targetDetected;
    } else if (elapsedMs < unavailableTimeoutMs) {
      return TargetScanStatus.staleReading;
    } else {
      return TargetScanStatus.temporarilyUnavailable;
    }
  }

  int? elapsedSinceLastSeenMs([DateTime? now]) {
    if (lastSeenTimestamp == null) return null;
    final current = now ?? DateTime.now();
    return current.difference(lastSeenTimestamp!).inMilliseconds;
  }

  String getReadingAgeString([DateTime? now]) {
    final ms = elapsedSinceLastSeenMs(now);
    if (ms == null) return 'No readings yet';
    if (ms < 1000) return 'Just now';
    final seconds = (ms / 1000.0).toStringAsFixed(1);
    return '${seconds}s ago';
  }

  String getDisplayLabel(TargetScanStatus status) {
    switch (status) {
      case TargetScanStatus.searching:
        return 'Searching for Beacon...';
      case TargetScanStatus.targetDetected:
        return 'Target Detected (Live)';
      case TargetScanStatus.measuring:
        return 'Measuring Telemetry...';
      case TargetScanStatus.signalFluctuating:
        return 'Signal Fluctuating';
      case TargetScanStatus.staleReading:
        return 'Stale Reading';
      case TargetScanStatus.temporarilyUnavailable:
        return 'Target Temporarily Unavailable';
      case TargetScanStatus.bluetoothDisabled:
        return 'Bluetooth Disabled';
      case TargetScanStatus.permissionRequired:
        return 'Permissions Required';
      case TargetScanStatus.scanningError:
        return 'Scanner Error';
      case TargetScanStatus.scanningUnavailable:
        return 'Scanning Unavailable';
    }
  }
}
