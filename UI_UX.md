# Foxhunt UI/UX Specification

## 1. UX Goal

The participant should understand the application within seconds.

The UI should answer three questions:

1.  **Did you find the transmitter?**
2.  **Am I getting closer?**
3.  **What should I do next?**

No networking terminology should be required to play the game.

------------------------------------------------------------------------

## 2. Design Principles

-   Minimal.
-   High contrast.
-   Large signal indicator.
-   One primary action at a time.
-   No password field.
-   No technical configuration in participant mode.
-   Useful feedback when detection fails.

------------------------------------------------------------------------

## 3. Screen 1: Welcome

``` text
┌─────────────────────────┐
│                         │
│        FOXHUNT          │
│                         │
│   Find the hidden       │
│   transmitter.          │
│                         │
│   Your phone will scan  │
│   nearby Wi-Fi signals. │
│                         │
│     [ START HUNT ]      │
│                         │
└─────────────────────────┘
```

------------------------------------------------------------------------

## 4. Screen 2: Permission Setup

``` text
┌─────────────────────────┐
│     READY TO SCAN       │
│                         │
│  Wi-Fi scanning needs   │
│  permission/settings    │
│  on your phone.         │
│                         │
│  ✓ Wi-Fi                │
│  ✓ Required permission  │
│  ✓ Required system      │
│    settings             │
│                         │
│    [ ENABLE SCANNING ]  │
└─────────────────────────┘
```

The app should explain requirements honestly. It should never claim it
can bypass system restrictions.

------------------------------------------------------------------------

## 5. Screen 3: Searching

``` text
┌─────────────────────────┐
│                         │
│       SEARCHING         │
│                         │
│          ◌             │
│                         │
│  Looking for the        │
│  hidden transmitter...  │
│                         │
│  Keep moving.           │
│                         │
└─────────────────────────┘
```

------------------------------------------------------------------------

## 6. Screen 4: Target Detected

Primary gameplay screen:

``` text
┌─────────────────────────┐
│      TRANSMITTER        │
│        DETECTED         │
│                         │
│          HOT            │
│                         │
│       -54 dBm           │
│                         │
│     ████████░░          │
│                         │
│       ↑ STRONGER        │
│                         │
│   Keep moving this way  │
│                         │
└─────────────────────────┘
```

The exact direction cannot be inferred from a single RSSI measurement.
The phrase "this way" should only be used if the application has enough
movement history to infer a direction/trend.

Otherwise:

``` text
Signal getting stronger.
Keep moving and compare.
```

------------------------------------------------------------------------

## 7. Hot/Cold Language

Recommended:

  State          User message
  -------------- --------------------
  Very Cold      Far away
  Cold           Getting started
  Warm           Getting closer
  Hot            Very close
  Very Hot       Extremely close
  Target Range   You found the zone

Avoid pretending RSSI gives exact distance.

------------------------------------------------------------------------

## 8. Signal Visualization

Primary indicator:

``` text
Very weak  ▂
Weak       ▂▄
Medium     ▂▄▆
Strong     ▂▄▆█
```

Secondary: - RSSI value. - Trend arrow. - State label.

The RSSI number should be secondary because most participants do not
naturally think in dBm.

------------------------------------------------------------------------

## 9. Lost Target

``` text
┌─────────────────────────┐
│     SIGNAL LOST         │
│                         │
│  The transmitter is no  │
│  longer visible.        │
│                         │
│  Move around and scan   │
│  again.                 │
│                         │
│     [ SCAN AGAIN ]      │
└─────────────────────────┘
```

------------------------------------------------------------------------

## 10. Success Screen

``` text
┌─────────────────────────┐
│                         │
│       FOUND IT!         │
│                         │
│          ✓              │
│                         │
│   You reached the       │
│   transmitter zone.     │
│                         │
│       [ FINISH ]        │
│                         │
└─────────────────────────┘
```

The success condition should be organizer-configurable and should not
rely solely on one RSSI number.

------------------------------------------------------------------------

## 11. Organizer Mode

Separate from participant mode.

Fields:

``` text
Target SSID
Target BSSID (optional)
Near threshold
Hot threshold
Warm threshold
Scanning behavior
```

The participant should not see these controls.

------------------------------------------------------------------------

## 12. Accessibility

-   Large text.
-   High contrast.
-   Do not use color as the only state indicator.
-   Haptic feedback optional.
-   Audio cues optional.
-   Screen-reader labels for signal states.
-   Avoid rapid flashing.

------------------------------------------------------------------------

## 13. UX Anti-Patterns

Do not:

-   Ask for the ESP32 password.
-   Ask the participant to join Wi-Fi.
-   Display raw technical errors without explanation.
-   Pretend RSSI equals exact distance.
-   Claim to know the physical direction without evidence.
-   Hide permission failures.
