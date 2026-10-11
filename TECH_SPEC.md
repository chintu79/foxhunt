# Foxhunt Technical Specification

## 1. Scope

This specification defines the MVP implementation for an Android
application that passively detects an ESP32 Wi-Fi transmitter without
connecting to it.

------------------------------------------------------------------------

## 2. Technology Stack

### Android

Recommended: - Kotlin - Android Studio - Jetpack Compose for UI -
Android Wi-Fi APIs - Kotlin Coroutines / Flow - ViewModel - DataStore
for local configuration

### ESP32

Recommended: - Arduino framework or ESP-IDF - ESP32 Wi-Fi SoftAP mode

The ESP32 does not need custom application networking for MVP.

------------------------------------------------------------------------

## 3. ESP32 Configuration

Example configuration:

``` text
SSID: FOXHUNT_01
Password: <organizer-only password>
Channel: configurable
```

The password exists only to protect the access point from participants
accidentally joining it. It is not used by the detection system.

The ESP32 should continuously run as a SoftAP.

Pseudo-flow:

``` text
boot
  ↓
initialize Wi-Fi
  ↓
start SoftAP
  ↓
keep running
```

------------------------------------------------------------------------

## 4. Android Wi-Fi Scanning

The app should use the Android Wi-Fi scanning APIs available to the
target API level.

Conceptual flow:

``` kotlin
wifiManager.startScan()

val results = wifiManager.scanResults

results.forEach { result ->
    val ssid = result.SSID
    val bssid = result.BSSID
    val rssi = result.level
}
```

Actual implementation must account for Android API-level permission
requirements, scan throttling, and device-specific behavior.

The application must never assume `startScan()` guarantees an immediate
fresh scan.

------------------------------------------------------------------------

## 5. Target Matching

Recommended configuration object:

``` kotlin
data class TargetConfig(
    val ssid: String,
    val bssid: String? = null
)
```

Matching:

``` kotlin
fun isTarget(result: ScanResult, config: TargetConfig): Boolean {
    if (config.bssid != null) {
        return result.BSSID.equals(config.bssid, ignoreCase = true)
    }

    return result.SSID == config.ssid
}
```

For production, BSSID is preferable when the event hardware is fixed.

------------------------------------------------------------------------

## 6. RSSI Processing

Raw RSSI is noisy.

Example samples:

``` text
-71
-68
-75
-66
-69
-64
```

Do not directly map every raw value to UI state.

Use a smoothing algorithm.

### Exponential Moving Average

``` kotlin
filtered = alpha * current + (1 - alpha) * previous
```

Recommended initial `alpha`:

``` text
0.2 - 0.35
```

Tune experimentally.

### Optional median filter

Use the median of the last N samples to suppress extreme spikes.

------------------------------------------------------------------------

## 7. Signal Trend

Calculate change over a short time window.

Because RSSI is negative:

``` text
-70 → -60 = stronger
-60 → -72 = weaker
```

Therefore:

``` kotlin
delta = currentFiltered - previousFiltered
```

Positive delta means stronger signal.

------------------------------------------------------------------------

## 8. Hot/Cold State

Do not rely exclusively on absolute RSSI because phones, cases, antenna
orientation, ESP32 placement, walls, and interference affect readings.

MVP should combine:

-   Current filtered RSSI.
-   Recent RSSI trend.
-   Optional calibrated target threshold.

Example:

``` text
filtered <= -45      VERY_HOT
-55 to -46           HOT
-65 to -56           WARM
-75 to -66           COLD
> -75                VERY_COLD
```

These values are starting points only and must be calibrated
experimentally.

------------------------------------------------------------------------

## 9. Sampling Strategy

The app should avoid aggressive scan requests because Android may
throttle Wi-Fi scans.

Recommended design:

``` text
Scan request
     ↓
Receive results
     ↓
Extract target
     ↓
Process RSSI
     ↓
Update UI
     ↓
Wait according to platform constraints
```

Do not create a tight loop calling `startScan()` continuously.

------------------------------------------------------------------------

## 10. State Model

``` kotlin
sealed class FoxhuntState {
    data object PermissionRequired : FoxhuntState()
    data object Scanning : FoxhuntState()
    data object TargetNotFound : FoxhuntState()

    data class TargetDetected(
        val rssi: Int,
        val filteredRssi: Double,
        val trend: Trend,
        val signalState: SignalState
    ) : FoxhuntState()

    data class Error(val message: String) : FoxhuntState()
}
```

------------------------------------------------------------------------

## 11. Privacy and Security

The app should not require:

-   Wi-Fi password.
-   Internet access.
-   ESP32 credentials.
-   Participant account.

Location permissions/settings may be required by Android for Wi-Fi
scanning on some API levels/device configurations. This does not mean
Foxhunt needs to collect or transmit the participant's geographic
location.

No permission-bypass mechanism shall be implemented.

------------------------------------------------------------------------

## 12. Testing

### Unit tests

-   SSID matching.
-   BSSID matching.
-   RSSI smoothing.
-   Trend calculation.
-   Signal state mapping.

### Device tests

Test on multiple Android versions and manufacturers.

### Physical tests

Test:

1.  Same room.
2.  Open field.
3.  Through walls.
4.  Behind doors.
5.  Different phone orientations.
6.  Multiple Wi-Fi networks.
7.  ESP32 at varying distances.

------------------------------------------------------------------------

## 13. MVP Technical Risks

### Risk: Android scan throttling

Mitigation: - Design around scan result availability. - Avoid excessive
scan calls.

### Risk: RSSI inconsistency

Mitigation: - Filtering. - Trend-based UX. - Physical calibration.

### Risk: Device-specific Wi-Fi behavior

Mitigation: - Test several Android devices. - Provide a compatibility
warning if scanning is unavailable.

### Risk: False target detection

Mitigation: - Prefer BSSID matching. - Use organizer-defined target
configuration.

------------------------------------------------------------------------

## 14. Definition of Done

Technical MVP is complete when:

-   ESP32 broadcasts.
-   Android discovers it.
-   No password is requested.
-   App does not connect to it.
-   RSSI is processed.
-   UI updates correctly.
-   Permission failures are handled.
-   Scan throttling does not crash/degrade the app into nonsense.
-   End-to-end physical hunt succeeds.
