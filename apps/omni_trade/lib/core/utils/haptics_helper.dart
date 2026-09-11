import 'package:flutter/services.dart';

/// Central helper for tactile micro-interactions in OmniTrade.
class HapticsHelper {
  HapticsHelper._();

  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void error() {
    HapticFeedback.vibrate();
  }
}
