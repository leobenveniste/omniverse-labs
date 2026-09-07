import 'package:flutter/widgets.dart';

/// UI/UX Pro Max layout grid spacing constants.
/// Enforces a strict 4px / 8px scale across all margins, paddings, gaps, and heights.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Radius constants
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 999.0;

  // Standard EdgeInsets
  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets paddingCard = EdgeInsets.all(md);
  static const EdgeInsets paddingDialog = EdgeInsets.all(lg);
  static const EdgeInsets paddingChip = EdgeInsets.symmetric(horizontal: sm, vertical: xs);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(horizontal: lg, vertical: sm);
}
