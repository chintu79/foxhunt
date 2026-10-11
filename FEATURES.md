# Foxhunt Feature Specification

## 1. MVP Features

### F-001 Automatic Wi-Fi Discovery

**Priority:** P0

Automatically scan available Wi-Fi networks and locate the configured
Foxhunt transmitter.

**Acceptance criteria:** - No manual SSID entry during normal
participant flow. - Target is identified from scan results. - Target
status is visible.

------------------------------------------------------------------------

### F-002 Password-Free Detection

**Priority:** P0

Detect the transmitter without requiring its Wi-Fi password.

**Acceptance criteria:** - No password prompt. - No network
association. - No connection to the ESP32 is required.

------------------------------------------------------------------------

### F-003 RSSI Monitoring

**Priority:** P0

Read and process the target network's RSSI.

**Acceptance criteria:** - Current signal information is displayed. -
Values update when new scan results arrive.

------------------------------------------------------------------------

### F-004 RSSI Smoothing

**Priority:** P0

Reduce signal jitter.

**Acceptance criteria:** - UI does not jump excessively from one sample
to another. - Short-lived outliers have limited effect.

------------------------------------------------------------------------

### F-005 Hot/Cold Engine

**Priority:** P0

Translate signal strength/trend into game-friendly states.

**States:** - Very Cold - Cold - Warm - Hot - Very Hot - Target Range

------------------------------------------------------------------------

### F-006 Target Lost Detection

**Priority:** P0

Detect when the transmitter disappears from scan results.

**Acceptance criteria:** - App does not incorrectly display stale "hot"
data indefinitely. - User receives a clear signal-lost state.

------------------------------------------------------------------------

### F-007 Permission Guidance

**Priority:** P0

Guide the participant through Android requirements.

**Acceptance criteria:** - Required permission is explained. - User can
navigate to the relevant system setting when necessary. - Denial is
handled gracefully.

------------------------------------------------------------------------

### F-008 Offline Operation

**Priority:** P0

Core hunt functionality works without internet.

**Acceptance criteria:** - No server connection required. - No account
required.

------------------------------------------------------------------------

## 2. P1 Features

### F-101 BSSID Target Lock

Lock onto a specific transmitter using BSSID.

Benefit: - Prevents same-SSID false positives.

### F-102 Haptic Feedback

Increase vibration intensity/frequency as the signal becomes stronger.

### F-103 Audio Feedback

Optional tones that change with signal strength.

### F-104 Signal History

Display a short history graph.

Example:

``` text
RSSI
-40 |       *
-50 |     *   *
-60 |   *
-70 | *
    +-------------
      time
```

### F-105 Calibration Mode

Organizer walks the venue and records expected RSSI ranges.

------------------------------------------------------------------------

## 3. P2 Features

### F-201 Multiple Transmitters

Support multiple hidden ESP32 units.

Example:

``` text
FOX-01
FOX-02
FOX-03
```

### F-202 Game Scoring

Track: - Completion time. - Checkpoint order. - Penalties.

### F-203 Event Configuration

Organizer can distribute a local event configuration package.

### F-204 Anti-Spoofing

Use transmitter-specific identity data to reduce false matches.

### F-205 Hunt History

Store previous hunt attempts locally.

------------------------------------------------------------------------

## 4. Experimental Features

### F-301 Direction Estimation

Estimate movement direction using RSSI changes over time.

Important limitation: A phone cannot derive true radio direction from
ordinary Wi-Fi RSSI alone.

Therefore this feature should be treated as a trend inference system,
not a compass.

### F-302 Distance Estimation

Estimate approximate distance from calibrated RSSI.

This is inherently unreliable across walls, people, device orientations,
and environments. It should never be presented as precise.

------------------------------------------------------------------------

## 5. Security Features

### S-001 No Password Exposure

Participant application never needs transmitter credentials.

### S-002 No Unauthorized Connection

Participant app does not connect to the ESP32.

### S-003 No Permission Bypass

Application uses supported Android APIs only.

### S-004 Local Configuration

Target identity can remain stored locally.

------------------------------------------------------------------------

## 6. Feature Priorities

  Feature                   Priority
  ------------------------- --------------
  Automatic discovery       P0
  Password-free detection   P0
  RSSI monitoring           P0
  RSSI smoothing            P0
  Hot/cold engine           P0
  Target lost state         P0
  Permission guidance       P0
  Offline operation         P0
  BSSID locking             P1
  Haptics                   P1
  Audio                     P1
  Signal history            P1
  Calibration               P1
  Multiple transmitters     P2
  Scoring                   P2
  Event configuration       P2
  Anti-spoofing             P2
  Direction estimation      Experimental
  Distance estimation       Experimental
