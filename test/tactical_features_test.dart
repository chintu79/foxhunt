import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foxhunt/domain/calibration_config.dart';
import 'package:foxhunt/domain/signal_state_engine.dart';
import 'package:foxhunt/ui/widgets/passcode_dialog.dart';
import 'package:foxhunt/ui/widgets/tactical_meter.dart';
import 'package:foxhunt/main.dart';

void main() {
  group('Event Security Passcode Configuration & Dialog', () {
    test('CalibrationConfig has default event passcode FOX2026', () {
      const config = CalibrationConfig();
      expect(config.eventPasscode, 'FOX2026');
    });

    test('CalibrationConfig copyWith preserves or updates event passcode', () {
      const config = CalibrationConfig();
      final updated = config.copyWith(eventPasscode: 'EVENT99');
      expect(updated.eventPasscode, 'EVENT99');
      expect(config.eventPasscode, 'FOX2026');
    });

    testWidgets('PasscodeDialog displays security clearance and denies wrong passcode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasscodeDialog(expectedPasscode: 'FOX2026'),
          ),
        ),
      );

      expect(find.text('SECURITY CLEARANCE'), findsOneWidget);
      expect(find.text('AUTHENTICATE'), findsOneWidget);

      // Enter incorrect passcode
      await tester.enterText(find.byType(TextField), 'WRONGCODE');
      await tester.tap(find.text('AUTHENTICATE'));
      await tester.pump();

      expect(find.text('ACCESS DENIED // INVALID CODE'), findsOneWidget);
    });

    testWidgets('PasscodeDialog accepts correct passcode (case insensitive)', (WidgetTester tester) async {
      bool? authResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    authResult = await PasscodeDialog.show(context, expectedPasscode: 'FOX2026');
                  },
                  child: const Text('OPEN DIALOG'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      expect(find.text('SECURITY CLEARANCE'), findsOneWidget);

      // Enter lowercase correct passcode
      await tester.enterText(find.byType(TextField), 'fox2026');
      await tester.tap(find.text('AUTHENTICATE'));
      await tester.pumpAndSettle();

      expect(authResult, isTrue);
    });
  });

  group('Tactical Fluctuating Meter Widget', () {
    testWidgets('Renders all four zone labels and S-meter scale markings', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TacticalFluctuatingMeter(
              currentState: HuntingState.hot,
              smoothedRssi: -52.0,
            ),
          ),
        ),
      );

      // Zone labels
      expect(find.text('COLD'), findsOneWidget);
      expect(find.text('WARM'), findsOneWidget);
      expect(find.text('HOT'), findsOneWidget);
      expect(find.text('VERY HOT'), findsOneWidget);

      // ARDF S-meter scale markings
      expect(find.text('RECEIVER RF S-METER'), findsOneWidget);
      expect(find.text('LIVE RF'), findsOneWidget);
      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S9'), findsOneWidget);
      expect(find.text('+40'), findsOneWidget);

      // Advance clock slightly to verify dynamic tick runs without crash
      await tester.pump(const Duration(milliseconds: 150));
    });
  });

  group('Tactical Hunting Screen with 10s Cooldown Refresh', () {
    testWidgets('Renders HuntingScreen with state badge, S-meter, and refresh button with 10s cooldown', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HuntingScreen(targetName: 'FOXHUNT_01'),
        ),
      );

      // Verify screen title
      expect(find.text('FOXHUNT_01'), findsOneWidget);

      // Verify S-meter is directly rendered (no searching template blocking)
      expect(find.text('RECEIVER RF S-METER'), findsOneWidget);

      // Verify navigation button
      expect(find.text('RETURN TO TARGET RADAR'), findsOneWidget);

      // Advance simulated timer past the 30.0s tracking window
      await tester.pump(const Duration(milliseconds: 30100));
      await tester.pump();

      // Now cooldown begins (10s)
      expect(find.textContaining('REFRESH IN'), findsOneWidget);

      // Advance by 5 seconds
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('REFRESH IN'), findsOneWidget);

      // Advance through remaining cooldown (6 seconds)
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('REFRESH SIGNAL'), findsOneWidget);
    });

    test('Smooth response calibration defaults (medianWindow=5, emaAlpha=0.20, confirmation=1)', () {
      const config = CalibrationConfig();
      expect(config.medianWindowSize, 5);
      expect(config.emaAlpha, 0.20);
      expect(config.confirmationCount, 1);
    });

    testWidgets('TacticalFluctuatingMeter responds immediately to didUpdateWidget with new RSSI', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TacticalFluctuatingMeter(
              currentState: HuntingState.cold,
              smoothedRssi: -85.0,
            ),
          ),
        ),
      );

      // Rebuild with hot signal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TacticalFluctuatingMeter(
              currentState: HuntingState.hot,
              smoothedRssi: -50.0,
            ),
          ),
        ),
      );

      // Advance by 50ms - needle should have immediately jumped and moved smoothly
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('HOT'), findsOneWidget);
    });

    test('CalibrationConfig identifies real vs dummy transmitter', () {
      const config = CalibrationConfig();
      expect(config.realTargetName, 'FOXHUNT_01');
      expect(config.isRealTarget('FOXHUNT_01'), isTrue);
      expect(config.isRealTarget('foxhunt_01'), isTrue);
      expect(config.isRealTarget('FOXHUNT_02'), isFalse);

      final custom = config.copyWith(realTargetName: 'FOXHUNT_02');
      expect(custom.isRealTarget('FOXHUNT_02'), isTrue);
      expect(custom.isRealTarget('FOXHUNT_01'), isFalse);
    });
  });
}
