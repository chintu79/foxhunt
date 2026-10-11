# Foxhunt System Architecture Document (SAD)

## 1. Architecture Summary

Foxhunt uses a **passive Wi-Fi discovery architecture**.

The ESP32 acts as a Wi-Fi access point. The Android application scans
nearby Wi-Fi networks and reads scan metadata. The application does not
authenticate with or connect to the ESP32.

``` text
┌──────────────────────┐
│       ESP32          │
│   Wi-Fi Access Point │
│   FOXHUNT_01         │
└──────────┬───────────┘
           │ Wi-Fi beacon
           ▼
┌─────────────────────────────┐
│      Android Wi-Fi Stack    │
│  Network scan / scan result │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│       Foxhunt App            │
│                             │
│  Discovery                  │
│      ↓                      │
│  Target Matcher             │
│      ↓                      │
│  RSSI Processor             │
│      ↓                      │
│  Signal State Engine        │
│      ↓                      │
│  UI / Haptics               │
└─────────────────────────────┘
```

------------------------------------------------------------------------

## 2. Major Components

### 2.1 ESP32 Transmitter

Responsibilities: - Start Wi-Fi SoftAP. - Advertise the configured
SSID. - Remain stationary. - Periodically broadcast Wi-Fi beacons
automatically.

The transmitter does not need an application-layer protocol for MVP.

### 2.2 Android Wi-Fi Scanner

Responsibilities: - Request/use permitted Android Wi-Fi scan APIs. -
Trigger scans subject to Android scan throttling. - Receive available
network scan results.

### 2.3 Target Discovery Service

Responsibilities: - Filter scan results. - Identify the Foxhunt
target. - Optionally validate BSSID. - Report target availability.

Suggested matching priority:

``` text
1. Exact BSSID match
2. Exact SSID + expected transmitter profile
3. Configured SSID prefix
```

### 2.4 RSSI Processor

Responsibilities: - Collect RSSI samples. - Reject invalid/outlier
values. - Smooth the signal. - Calculate short-term trend.

A moving median or exponential moving average is appropriate for MVP.

Example:

``` text
filtered = alpha * currentRSSI + (1-alpha) * previousFiltered
```

### 2.5 Signal State Engine

Converts RSSI/trend into user-facing states.

Example states:

-   NOT_FOUND
-   VERY_COLD
-   COLD
-   WARM
-   HOT
-   VERY_HOT
-   TARGET_RANGE

Thresholds must be configurable because physical environments vary
dramatically.

### 2.6 UI Layer

Displays: - Target status. - Signal strength. - Trend. - Hot/cold
state. - Scan status. - Permission/error recovery.

------------------------------------------------------------------------

## 3. Data Flow

``` text
ESP32 beacon
     ↓
Android Wi-Fi scan
     ↓
ScanResult list
     ↓
Target matcher
     ↓
RSSI sample
     ↓
Smoothing
     ↓
Trend calculation
     ↓
Signal state
     ↓
UI
```

No application data travels through the ESP32.

------------------------------------------------------------------------

## 4. Connectivity Model

### Required

-   Wi-Fi radio enabled on participant device.
-   Android Wi-Fi scanning available.

### Not required

-   Internet.
-   Cellular data.
-   Association with ESP32.
-   ESP32 password.
-   ESP32 IP address.
-   TCP/UDP communication.

------------------------------------------------------------------------

## 5. Permission Architecture

The application shall use Android's supported permission mechanisms.

The exact permission requirements depend on the Android API level and
device implementation.

The application must:

1.  Detect missing permissions/settings.
2.  Explain why they are required.
3.  Request the minimum necessary permissions.
4.  Detect denial.
5.  Provide recovery instructions.

The application shall not attempt to bypass Android security
restrictions.

------------------------------------------------------------------------

## 6. Failure Modes

### Transmitter not found

Possible causes: - ESP32 powered off. - Out of range. - SSID mismatch. -
Scan unavailable. - Permissions/settings unavailable.

UI response: `Searching for Foxhunt transmitter...`

### Signal unstable

Response: - Continue collecting samples. - Use smoothing. - Show trend
rather than raw RSSI alone.

### Android scan throttling

Response: - Use available scan results. - Avoid requesting scans
excessively. - Update UI based on latest valid result.

### Multiple matching networks

Response: - Prefer configured BSSID. - Otherwise require an unambiguous
target identity.

------------------------------------------------------------------------

## 7. Architecture Principles

1.  **Passive over connected.**
2.  **Local over cloud.**
3.  **Simple hardware over custom hardware.**
4.  **Public Android APIs over permission bypasses.**
5.  **Smoothed signal over raw RSSI.**
6.  **Graceful failure over silent failure.**

------------------------------------------------------------------------

## 8. Future Architecture

For multi-transmitter events:

``` text
                 Event Configuration
                        │
             ┌──────────┴──────────┐
             ▼                     ▼
        FOXHUNT_01             FOXHUNT_02
             │                     │
             └──────────┬──────────┘
                        ▼
                Android Scanner
                        ▼
                 Target Resolver
                        ▼
              Game/Scoring Engine
```

The architecture should keep target identification separate from RSSI
processing so multiple transmitters can be supported later.
