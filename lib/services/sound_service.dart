import 'package:flutter/services.dart';

class SoundService {
  static const MethodChannel _channel = MethodChannel('com.example.foxhunt/sound');

  /// Distinct sound for the REAL transmitter: high-frequency confirmation chime + heavy haptic
  static Future<void> playRealSound() async {
    try {
      HapticFeedback.heavyImpact();
      await _channel.invokeMethod('playRealSound');
    } catch (_) {
      // Gracefully handled for host-based widget tests or uninitialized audio
    }
  }

  /// Distinct sound for the DUMMY/EMPTY transmitter: low-frequency decoy warning buzz + vibration
  static Future<void> playDummySound() async {
    try {
      HapticFeedback.vibrate();
      await _channel.invokeMethod('playDummySound');
    } catch (_) {
      // Gracefully handled for host-based widget tests or uninitialized audio
    }
  }
}
