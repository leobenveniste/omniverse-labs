import 'package:flutter/material.dart';

/// UI/UX Pro Max typography scale for OmniTrade.
/// Enforces: exactly 3 font weights (w400 Regular, w500 Medium, w700 Bold)
/// and 4 distinct type sizes (Display 24, Title/Section 18, Body 14, Caption 12).
class AppTypography {
  AppTypography._();

  static const double sizeDisplay = 24.0;
  static const double sizeSection = 18.0;
  static const double sizeBody = 14.0;
  static const double sizeCaption = 12.0;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightBold = FontWeight.w700;

  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  static TextStyle display(Color color) => TextStyle(
        fontSize: sizeDisplay,
        fontWeight: weightBold,
        height: 32.0 / sizeDisplay,
        letterSpacing: -0.5,
        color: color,
        fontFeatures: tabularFigures,
      );

  static TextStyle title(Color color) => TextStyle(
        fontSize: sizeSection,
        fontWeight: weightBold,
        height: 24.0 / sizeSection,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle section(Color color) => TextStyle(
        fontSize: sizeSection,
        fontWeight: weightBold,
        height: 24.0 / sizeSection,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle body(Color color, {bool isMedium = false, bool isBold = false}) => TextStyle(
        fontSize: sizeBody,
        fontWeight: isBold ? weightBold : (isMedium ? weightMedium : weightRegular),
        height: 20.0 / sizeBody,
        color: color,
        fontFeatures: tabularFigures,
      );

  static TextStyle caption(Color color, {bool isMedium = false, bool isBold = false}) => TextStyle(
        fontSize: sizeCaption,
        fontWeight: isBold ? weightBold : (isMedium ? weightMedium : weightRegular),
        height: 16.0 / sizeCaption,
        letterSpacing: 0.2,
        color: color,
        fontFeatures: tabularFigures,
      );
}
