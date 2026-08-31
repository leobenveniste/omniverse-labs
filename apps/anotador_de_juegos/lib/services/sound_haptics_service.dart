import 'package:flutter/services.dart';

class SoundHapticsService {
  static bool hapticsEnabled = true;

  static void click() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void pointAdded() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void pointSubtracted() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  static void diceRolled() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void winnerCelebration() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        HapticFeedback.heavyImpact();
      });
    }
  }
}
