import 'package:flutter_test/flutter_test.dart';
import 'package:foxhunt/domain/target_matcher.dart';
import 'package:foxhunt/domain/calibration_config.dart';
import 'package:foxhunt/domain/rssi_processor.dart';
import 'package:foxhunt/domain/signal_state_engine.dart';
import 'package:foxhunt/data/scanner_repository.dart';

void main() {
  group('TargetMatcher', () {
    test('matches by SSID', () {
      final matcher = TargetMatcher(config: TargetConfig(ssid: 'FOXHUNT_01'));
      final results = [
        ScanResultModel(ssid: 'HOME_WIFI', bssid: '11:22', rssi: -50),
        ScanResultModel(ssid: 'FOXHUNT_01', bssid: '33:44', rssi: -60),
      ];
      final target = matcher.findTarget(results);
      expect(target?.ssid, 'FOXHUNT_01');
    });

    test('matches by BSSID if provided', () {
      final matcher = TargetMatcher(config: TargetConfig(ssid: 'FOXHUNT_01', bssid: 'aa:bb'));
      final results = [
        ScanResultModel(ssid: 'FOXHUNT_01', bssid: '33:44', rssi: -60),
        ScanResultModel(ssid: 'FOXHUNT_01', bssid: 'AA:BB', rssi: -50),
      ];
      final target = matcher.findTarget(results);
      expect(target?.bssid, 'AA:BB');
    });
  });

  group('RssiProcessor', () {
    test('calculates EMA', () {
      final processor = RssiProcessor(
        config: const CalibrationConfig(medianWindowSize: 1, emaAlpha: 0.5),
      );
      processor.processSample(-70);
      expect(processor.filteredRssi, -70.0);
      
      processor.processSample(-50);
      // 0.5 * -50 + 0.5 * -70 = -25 - 35 = -60
      expect(processor.filteredRssi, -60.0);
    });

    test('calculates trend', () {
      final processor = RssiProcessor(
        config: const CalibrationConfig(medianWindowSize: 1, emaAlpha: 0.5, trendDeltaThreshold: 1.0),
      );
      processor.processSample(-70);
      processor.processSample(-50); // goes to -60.0
      
      final trend = processor.calculateTrend();
      expect(trend, SignalTrend.improving);
    });
  });

  group('SignalStateEngine', () {
    test('maps correctly', () {
      final engine = SignalStateEngine(
        config: const CalibrationConfig(confirmationCount: 1),
      );
      expect(engine.processSample(-95), HuntingState.cold);
      expect(engine.processSample(-85), HuntingState.warm);
      expect(engine.processSample(-75), HuntingState.hot);
      expect(engine.processSample(-68), HuntingState.veryHot);
    });
  });
}
