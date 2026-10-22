import 'package:flutter_test/flutter_test.dart';
import 'package:foxhunt/domain/calibration_config.dart';
import 'package:foxhunt/domain/rssi_processor.dart';
import 'package:foxhunt/domain/signal_state_engine.dart';
import 'package:foxhunt/domain/target_scan_status.dart';

void main() {
  group('Mechanic B - RSSI Filtering and Smoothing', () {
    test('Median filter rejects solitary outlier spike', () {
      final config = CalibrationConfig(
        medianWindowSize: 5,
        emaAlpha: 0.3,
      );
      final processor = RssiProcessor(config: config);

      // Baseline readings around -80 dBm
      processor.processSample(-80);
      processor.processSample(-80);
      // Sudden sharp spike (e.g. reflection / multipath artifact)
      processor.processSample(-25);
      processor.processSample(-80);
      processor.processSample(-80);

      // The median of [-80, -80, -25, -80, -80] is -80.
      expect(processor.lastMedianRssi, -80.0);
      // The smoothed RSSI should stay around -80 and not jump towards -25
      expect(processor.filteredRssi!, closeTo(-80.0, 1.0));
    });

    test('EMA smoothly follows sustained signal change', () {
      final config = CalibrationConfig(
        medianWindowSize: 3,
        emaAlpha: 0.5,
      );
      final processor = RssiProcessor(config: config);

      processor.processSample(-80);
      processor.processSample(-80);
      processor.processSample(-80);
      expect(processor.filteredRssi, -80.0);

      // Sustained step change to -60
      processor.processSample(-60);
      processor.processSample(-60);
      processor.processSample(-60);

      // Value should smoothly transition towards -60
      expect(processor.filteredRssi!, greaterThan(-75.0));
      expect(processor.filteredRssi!, lessThanOrEqualTo(-60.0));
    });
  });

  group('Mechanic B - Trend Detection', () {
    test('Deadband ignores minor fluctuations', () {
      final config = CalibrationConfig(
        medianWindowSize: 3,
        emaAlpha: 0.5,
        trendDeltaThreshold: 2.0,
      );
      final processor = RssiProcessor(config: config);

      processor.processSample(-60);
      processor.processSample(-60);
      processor.processSample(-60);
      processor.processSample(-61); // 1 dB fluctuation
      processor.processSample(-59); // 1 dB fluctuation

      expect(processor.calculateTrend(), SignalTrend.stable);
    });

    test('Detects genuine improving and worsening trends', () {
      final config = CalibrationConfig(
        medianWindowSize: 3,
        emaAlpha: 0.5,
        trendDeltaThreshold: 2.0,
        trendBaselineWindow: 2,
      );
      final processor = RssiProcessor(config: config);

      // Start at -75 dBm
      processor.processSample(-75);
      processor.processSample(-75);
      processor.processSample(-75);

      // Move closer: -55 dBm
      processor.processSample(-55);
      processor.processSample(-55);
      processor.processSample(-55);

      expect(processor.calculateTrend(), SignalTrend.improving);

      // Move away: -85 dBm
      processor.processSample(-85);
      processor.processSample(-85);
      processor.processSample(-85);

      expect(processor.calculateTrend(), SignalTrend.worsening);
    });
  });

  group('Mechanic B - Signal Stability and Confidence', () {
    test('Identifies insufficient readings, stable signal, and fluctuating signal', () {
      final config = CalibrationConfig(
        medianWindowSize: 5,
        stabilityStdDevThreshold: 3.0,
        minSamplesForStability: 3,
      );
      final processor = RssiProcessor(config: config);

      // Less than 3 samples
      processor.processSample(-60);
      expect(processor.calculateStability(), SignalStability.insufficientReadings);

      // Consistent readings
      processor.processSample(-60);
      processor.processSample(-61);
      processor.processSample(-60);
      processor.processSample(-59);
      expect(processor.calculateStability(), SignalStability.stable);

      // Erratic readings with high variance
      processor.reset();
      processor.processSample(-40);
      processor.processSample(-85);
      processor.processSample(-45);
      processor.processSample(-80);
      processor.processSample(-50);
      expect(processor.calculateStability(), SignalStability.fluctuating);
    });
  });

  group('Mechanic B - Hysteresis and State Stability', () {
    test('Hysteresis prevents flickering across boundaries', () {
      final config = CalibrationConfig(
        coldToWarmThreshold: -70.0,
        warmToHotThreshold: -58.0,
        hotToVeryHotThreshold: -46.0,
        hysteresisMargin: 4.0, // Exit Hot requires < (-58 - 4) = -62.0 dBm
        confirmationCount: 2,
      );
      final engine = SignalStateEngine(config: config);

      expect(engine.currentState, HuntingState.cold);

      // Transition to Warm requires 2 consecutive samples >= -70.0
      engine.processSample(-68.0);
      expect(engine.currentState, HuntingState.cold); // pending count = 1
      engine.processSample(-68.0);
      expect(engine.currentState, HuntingState.warm); // confirmed

      // Transition to Hot requires 2 consecutive samples >= -58.0
      engine.processSample(-56.0);
      engine.processSample(-56.0);
      expect(engine.currentState, HuntingState.hot);

      // Fluctuate down to -60.0 dBm (below entry -58, but above exit -62)
      engine.processSample(-60.0);
      engine.processSample(-60.0);
      // Because of hysteresis, state stays Hot!
      expect(engine.currentState, HuntingState.hot);

      // Fall to -64.0 dBm (below exit threshold of -62.0)
      engine.processSample(-64.0);
      engine.processSample(-64.0);
      expect(engine.currentState, HuntingState.warm);
    });

    test('Fluctuating signal does not prematurely trigger Hot or Very Hot', () {
      final config = CalibrationConfig(
        warmToHotThreshold: -58.0,
        confirmationCount: 1,
      );
      final engine = SignalStateEngine(config: config);

      // Send strong reading but with fluctuating stability
      engine.processSample(-50.0, stability: SignalStability.fluctuating);
      // State should not become Hot because of stability guard
      expect(engine.currentState, isNot(HuntingState.hot));
    });
  });

  group('Mechanic B - Target Scan Status & Liveness', () {
    test('Tracks live, stale, and unavailable states correctly based on elapsed time', () {
      final tracker = TargetStatusTracker(
        staleTimeoutMs: 3000,
        unavailableTimeoutMs: 7000,
      );

      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      // Initially searching
      expect(tracker.evaluateStatus(now: t0), TargetScanStatus.searching);

      // Packet arrives at t0 (with enough samples to pass measuring)
      tracker.recordTargetSeen(t0);
      expect(tracker.evaluateStatus(now: t0, validSampleCount: 3), TargetScanStatus.targetDetected);

      // 2 seconds later (still fresh < 3s)
      final t1 = t0.add(const Duration(seconds: 2));
      expect(tracker.evaluateStatus(now: t1, validSampleCount: 3), TargetScanStatus.targetDetected);

      // 4 seconds later (stale: 3s <= elapsed < 7s)
      final t2 = t0.add(const Duration(seconds: 4));
      expect(tracker.evaluateStatus(now: t2), TargetScanStatus.staleReading);
      expect(tracker.elapsedSinceLastSeenMs(t2), 4000);

      // 8 seconds later (temporarily unavailable >= 7s)
      final t3 = t0.add(const Duration(seconds: 8));
      expect(tracker.evaluateStatus(now: t3), TargetScanStatus.temporarilyUnavailable);

      // Bluetooth turned off
      tracker.updateBluetoothStatus(false);
      expect(tracker.evaluateStatus(now: t3), TargetScanStatus.bluetoothDisabled);

      // Bluetooth restored and target reappears automatically
      tracker.updateBluetoothStatus(true);
      final t4 = t0.add(const Duration(seconds: 10));
      tracker.recordTargetSeen(t4);
      expect(tracker.evaluateStatus(now: t4, validSampleCount: 3), TargetScanStatus.targetDetected);
    });
  });
}
