import '../data/scanner_repository.dart';

class TargetConfig {
  final String ssid;
  final String? bssid;
  final String? serviceUuid;
  final int? manufacturerId;

  TargetConfig({
    required this.ssid,
    this.bssid,
    this.serviceUuid,
    this.manufacturerId,
  });
}

class TargetMatcher {
  final TargetConfig config;

  TargetMatcher({required this.config});

  ScanResultModel? findTarget(List<ScanResultModel> results) {
    try {
      // 1. Highest precedence: Stable Service UUID if configured
      if (config.serviceUuid != null && config.serviceUuid!.isNotEmpty) {
        final targetUuid = config.serviceUuid!.trim().toLowerCase();
        final match = results.cast<ScanResultModel?>().firstWhere(
          (result) => result != null && result.serviceUuids.any((u) => u.toLowerCase() == targetUuid),
          orElse: () => null,
        );
        if (match != null) return match;
      }

      // 2. Hardware address / BSSID / UUID if configured
      if (config.bssid != null && config.bssid!.isNotEmpty) {
        final targetBssid = config.bssid!.trim().toLowerCase();
        final match = results.cast<ScanResultModel?>().firstWhere(
          (result) => result != null && result.bssid.trim().toLowerCase() == targetBssid,
          orElse: () => null,
        );
        if (match != null) return match;
      }

      // 3. Manufacturer identifier if configured
      if (config.manufacturerId != null) {
        final match = results.cast<ScanResultModel?>().firstWhere(
          (result) => result != null && result.manufacturerData.containsKey(config.manufacturerId),
          orElse: () => null,
        );
        if (match != null) return match;
      }

      // 4. Advertised Local Name (SSID)
      final targetSsid = config.ssid.trim().toLowerCase();
      final normTarget = targetSsid.replaceAll('foxhunt_0', 'foxhunt_');
      return results.cast<ScanResultModel?>().firstWhere(
        (result) {
          if (result == null) return false;
          final advSsid = result.ssid.trim().toLowerCase();
          final normAdv = advSsid.replaceAll('foxhunt_0', 'foxhunt_');
          return advSsid == targetSsid || normAdv == normTarget;
        },
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }
}
