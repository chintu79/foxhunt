# Foxhunt Product Requirements Document (PRD)

## 1. Product Overview

**Product:** Foxhunt\
**Version:** MVP 1.0\
**Platform:** Android\
**Primary hardware:** ESP32 configured as a Wi-Fi access
point/transmitter\
**Primary use case:** A participant uses a phone to locate a hidden
ESP32 transmitter by observing Wi-Fi signal strength.

### Core Principle

The participant must **not need to enter the ESP32 Wi-Fi password and
must not connect to the ESP32 network**.

The phone passively scans nearby Wi-Fi networks, identifies the Foxhunt
transmitter from its advertised Wi-Fi information, reads signal strength
(RSSI), smooths the readings, and presents a hot/cold locating
interface.

------------------------------------------------------------------------

## 2. Problem Statement

Traditional treasure-hunt or foxhunt systems require dedicated RF
receivers, custom hardware, or a network connection to the hidden
transmitter. Those approaches increase cost, setup time, and participant
friction.

Foxhunt uses hardware participants already carry: an Android phone with
Wi-Fi.

The hidden ESP32 continuously advertises a Wi-Fi access point. The
mobile app detects that broadcast without authenticating to it.

------------------------------------------------------------------------

## 3. Goals

### Primary goals

1.  Automatically discover the configured ESP32 transmitter.
2.  Detect the transmitter without requiring its password.
3.  Display real-time approximate signal strength.
4.  Smooth noisy RSSI measurements so the UI is usable.
5.  Give participants an intuitive hot/cold navigation signal.
6.  Work locally without internet connectivity.
7.  Require minimal participant setup.
8.  Keep transmitter hardware inexpensive and simple.

### Secondary goals

1.  Support multiple transmitter identities in future versions.
2.  Provide optional game modes and scoring.
3.  Support hidden physical placement of transmitters.
4.  Provide organizer configuration without exposing secrets to
    participants.

------------------------------------------------------------------------

## 4. Non-Goals for MVP

-   Connecting the participant phone to the ESP32 network.
-   Sending data to or from the ESP32 over IP.
-   Internet-based multiplayer.
-   GPS-based route navigation.
-   Guaranteed meter-level distance estimation.
-   Circumventing Android security or permission controls.
-   Reading arbitrary radio information unavailable through Android's
    public APIs.

------------------------------------------------------------------------

## 5. Users

### Participant

A person searching for the hidden transmitter.

Needs: - Immediate scanning. - Clear signal direction/trend. - No
password entry. - Minimal configuration. - Simple visual feedback.

### Organizer

The person configuring the event.

Needs: - Configure transmitter identity. - Test transmitter
visibility. - Optionally configure multiple transmitters. - Control game
parameters.

------------------------------------------------------------------------

## 6. Core User Journey

1.  Participant installs/opens Foxhunt.
2.  App explains required Wi-Fi/location permissions.
3.  Participant grants permissions and enables required device settings.
4.  App begins scanning.
5.  App identifies the configured Foxhunt transmitter.
6.  App displays signal strength and hot/cold status.
7.  Participant walks around.
8.  App continuously updates smoothed RSSI.
9.  Signal becomes stronger as the participant approaches the
    transmitter.
10. App shows a strong/near-target state when the signal reaches the
    configured threshold.
11. Participant physically finds the hidden transmitter.

------------------------------------------------------------------------

## 7. Functional Requirements

### FR-01 Automatic discovery

The app shall scan nearby Wi-Fi networks and automatically identify the
Foxhunt transmitter.

### FR-02 Password-free detection

The app shall not request, store, or require the ESP32 Wi-Fi password
for detection.

### FR-03 Passive detection

The app shall not need to associate with or connect to the ESP32
network.

### FR-04 RSSI display

The app shall display the detected transmitter's current and/or smoothed
RSSI.

### FR-05 Signal trend

The app shall indicate whether signal strength is improving or
worsening.

### FR-06 Hot/cold indicator

The app shall translate signal trends into understandable states such as
Cold, Warm, Hot, and Very Hot.

### FR-07 Scanning state

The app shall clearly indicate when it is scanning, waiting for results,
or has lost the transmitter.

### FR-08 Permission handling

The app shall explain required Android permissions and provide
actionable guidance if scanning is unavailable.

### FR-09 No-password UX

There shall be no participant-facing password form in the normal game
flow.

### FR-10 Target identity

The app shall use an organizer-configured target identity, such as SSID
plus optional BSSID validation.

------------------------------------------------------------------------

## 8. Non-Functional Requirements

### Performance

-   UI should remain responsive while scanning.
-   RSSI display should update without excessive flicker.
-   Signal smoothing should hide short-lived measurement spikes.

### Reliability

-   Temporary scan failures shall not crash the app.
-   Loss of the transmitter shall be distinguishable from a weak signal.
-   Permission denial shall produce a useful recovery path.

### Privacy

-   No participant location data is required for core operation.
-   No network password is required.
-   No internet service is required for core gameplay.

### Security

-   The app shall use Android public Wi-Fi APIs.
-   It shall not attempt to bypass Android permission enforcement.
-   Organizer-only configuration should not expose unnecessary
    credentials.

------------------------------------------------------------------------

## 9. Success Metrics

MVP success means:

-   A participant can open the app and begin searching without entering
    a password.
-   The app reliably identifies the intended ESP32 transmitter in the
    test environment.
-   RSSI changes are understandable while walking around.
-   The participant can locate the transmitter using only the app's
    signal feedback.
-   The system works without internet access.

------------------------------------------------------------------------

## 10. MVP Acceptance Criteria

A build is MVP-ready when:

1.  ESP32 is broadcasting the configured SSID.
2.  Android app can discover it through Wi-Fi scanning.
3.  No password is requested.
4.  RSSI is displayed.
5.  RSSI is smoothed.
6.  Hot/cold state changes according to configurable thresholds/trend.
7.  App handles missing permissions gracefully.
8.  App handles transmitter disappearance gracefully.
9.  App does not connect to the ESP32.
10. A complete test hunt can be performed end-to-end.

------------------------------------------------------------------------

## 11. Future Enhancements

-   Multiple fox transmitters.
-   Organizer dashboard.
-   Event codes.
-   Anti-spoofing transmitter identity.
-   Direction/trend visualization.
-   Audio/haptic feedback.
-   Heatmap/history.
-   Game scoring.
-   Time penalties.
-   Offline event packages.
