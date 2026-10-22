import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultModel {
  final String ssid; // Advertised device name (LocalName)
  final String bssid; // Hardware MAC (Android) or peripheral UUID (iOS)
  final int rssi; // Received Signal Strength Indicator in dBm
  final DateTime timestamp; // Actual scan arrival timestamp
  final List<String> serviceUuids; // Advertised service UUIDs
  final Map<int, List<int>> manufacturerData; // Raw manufacturer data

  ScanResultModel({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    DateTime? timestamp,
    this.serviceUuids = const [],
    this.manufacturerData = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  /// Validates whether the RSSI reading is physically plausible.
  /// Typically valid BLE RSSI is between -120 dBm (noise floor) and 0 dBm (antenna touching).
  /// Readings > 0 dBm or < -120 dBm (or 127 = BLE hardware error) are rejected.
  bool get isValidRssi => rssi <= 0 && rssi >= -120;
}

class ScannerRepository {
  Stream<List<ScanResultModel>> get scanResultsStream {
    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
        final serviceUuids = r.advertisementData.serviceUuids.map((g) => g.toString().toLowerCase()).toList();
        final name = r.device.advName.isNotEmpty 
            ? r.device.advName 
            : (r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : 'Unknown Device');

        return ScanResultModel(
          ssid: name,
          bssid: r.device.remoteId.str,
          rssi: r.rssi,
          timestamp: r.timeStamp,
          serviceUuids: serviceUuids,
          manufacturerData: r.advertisementData.manufacturerData,
        );
      }).where((model) => model.isValidRssi).toList();
    });
  }

  Future<bool> startScan({Duration? timeout, String? targetName}) async {
    try {
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        final List<String> names = (targetName != null && targetName.isNotEmpty)
            ? {targetName, targetName.toUpperCase(), targetName.toLowerCase()}.toList()
            : const [];

        await FlutterBluePlus.startScan(
          timeout: timeout,
          continuousUpdates: true,
          continuousDivisor: 1,
          oneByOne: true,
          androidScanMode: AndroidScanMode.lowLatency,
          withNames: names,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Failed to start BLE scan: $e");
      return false;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Failed to stop BLE scan: $e");
    }
  }
}
