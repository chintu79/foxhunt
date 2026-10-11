import '../data/scanner_repository.dart';

class TargetConfig {
  final String ssid;
  final String? bssid;

  TargetConfig({required this.ssid, this.bssid});
}

class TargetMatcher {
  final TargetConfig config;

  TargetMatcher({required this.config});

  ScanResultModel? findTarget(List<ScanResultModel> results) {
    try {
      if (config.bssid != null && config.bssid!.isNotEmpty) {
        return results.firstWhere(
            (result) => result.bssid.trim().toLowerCase() == config.bssid!.trim().toLowerCase());
      }
      
      final targetSsid = config.ssid.trim().toLowerCase();
      return results.firstWhere((result) => result.ssid.trim().toLowerCase() == targetSsid);
    } catch (e) {
      return null;
    }
  }
}
