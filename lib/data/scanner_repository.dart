import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultModel {
  final String ssid; // We'll map the BLE device name to this for compatibility
  final String bssid; // We'll map the BLE MAC/UUID to this
  final int rssi;

  ScanResultModel({required this.ssid, required this.bssid, required this.rssi});
}

class ScannerRepository {
  Stream<List<ScanResultModel>> get scanResultsStream {
    return FlutterBluePlus.scanResults.map((results) {
      return results.map((r) {
        return ScanResultModel(
          ssid: r.device.advName.isNotEmpty ? r.device.advName : (r.advertisementData.localName.isNotEmpty ? r.advertisementData.localName : 'Unknown Device'),
          bssid: r.device.remoteId.str,
          rssi: r.rssi,
        );
      }).toList();
    });
  }

  Future<bool> startScan({Duration? timeout}) async {
    try {
      // FlutterBluePlus requires bluetooth to be on. We assume permissions are handled.
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
        await FlutterBluePlus.startScan(
          timeout: timeout, 
          continuousUpdates: true
        );
        return true;
      }
      return false;
    } catch (e) {
      print("Failed to start BLE scan: $e");
      return false;
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }
}
