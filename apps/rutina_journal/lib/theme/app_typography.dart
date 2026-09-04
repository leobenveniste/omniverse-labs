import 'package:flutter/material.dart';

/// UI/UX Pro Max typography scale.
/// Strict constraint: exactly 3 font weights (w400, w500, w700) and 4 distinct type sizes.
class AppTypography {
  AppTypography._();

  static const double sizeDisplay = 24.0;
  static const double sizeSection = 18.0;
  static const double sizeBody = 14.0;
  static const double sizeCaption = 12.0;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightBold = FontWeight.w700;

  static TextStyle display(Color color) => TextStyle(
        fontSize: sizeDisplay,
        fontWeight: weightBold,
        height: 32.0 / sizeDisplay,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle section(Color color) => TextStyle(
        fontSize: sizeSection,
        fontWeight: weightBold,
        height: 24.0 / sizeSection,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle body(Color color, {bool isMedium = false}) => TextStyle(
        fontSize: sizeBody,
        fontWeight: isMedium ? weightMedium : weightRegular,
        height: 20.0 / sizeBody,
        color: color,
      );

  static TextStyle caption(Color color, {bool isMedium = false}) => TextStyle(
        fontSize: sizeCaption,
        fontWeight: isMedium ? weightMedium : weightRegular,
        height: 16.0 / sizeCaption,
        letterSpacing: 0.2,
        color: color,
      );
}
