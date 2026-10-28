import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Strict Typography System adhering to GEMINI.md:
/// - Maximum 3 font weights: Regular (400), Medium (500), Bold (700).
/// - Maximum 4 distinct type sizes:
///   1. Display / Hero Title: 24sp
///   2. Subhead / Section Title: 18sp
///   3. Body / Checklist: 14sp
///   4. Caption / Tag / Meta: 12sp
abstract class AppTypography {
  // --- 1. Display / Hero (24sp, Bold 700) ---
  static TextStyle displaySerif({required Color color}) {
    return GoogleFonts.cinzel(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: color,
      height: 1.2,
    );
  }

  static TextStyle displaySans({required Color color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: color,
      height: 1.25,
    );
  }

  // --- 2. Subhead / Card Titles (18sp, Bold 700 or Medium 500) ---
  static TextStyle subheadSerif({required Color color, bool bold = true}) {
    return GoogleFonts.cinzel(
      fontSize: 18,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: 0.8,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle subheadSans({required Color color, bool bold = true}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: -0.2,
      color: color,
      height: 1.3,
    );
  }

  // --- 3. Body / Interactive Items (14sp, Regular 400 or Medium 500) ---
  static TextStyle body({required Color color, bool medium = false}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: medium ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: 0.1,
      color: color,
      height: 1.45,
    );
  }

  static TextStyle bodySmall({required Color color, bool medium = false}) {
    return caption(color: color, medium: medium);
  }

  static TextStyle subhead({required Color color, bool bold = false}) {
    return subheadSans(color: color, bold: bold);
  }

  // Monospace for Airport codes, Flight details, Weights, and MRZ strip
  static TextStyle monoBody({required Color color, bool medium = false}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: medium ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: 0.5,
      color: color,
      height: 1.35,
    );
  }

  // --- 4. Caption / Tag / Meta (12sp, Medium 500 or Regular 400) ---
  static TextStyle caption({required Color color, bool medium = true}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: medium ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: 0.3,
      color: color,
      height: 1.35,
    );
  }

  static TextStyle monoCaption({required Color color, bool medium = true}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: medium ? FontWeight.w500 : FontWeight.w400,
      letterSpacing: 0.8,
      color: color,
      height: 1.3,
    );
  }

  // Consular Machine Readable Zone (MRZ) - 12sp mono uppercase
  static TextStyle mrzStrip({required Color color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.8,
      color: color,
      height: 1.4,
    );
  }
}
