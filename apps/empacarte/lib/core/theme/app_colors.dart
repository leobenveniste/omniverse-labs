import 'package:flutter/material.dart';

/// Design tokens for EmpacArte palette.
/// Follows strict WCAG AA contrast standards across both Light and Dark themes.
abstract class AppColors {
  // --- Burgundy Leather (Passport Signature) ---
  static const Color burgundyBase = Color(0xFF4A1521);
  static const Color burgundyDeep = Color(0xFF320B14);
  static const Color burgundyDark = Color(0xFF320B14);
  static const Color burgundyLight = Color(0xFF6B2333);
  static const Color burgundySurfaceDark = Color(0xFF240A10);

  // --- Gold Foil Embossing ---
  static const Color goldFoil = Color(0xFFC5A059);
  static const Color goldFoilLight = Color(0xFFDFBF75);
  static const Color goldFoilDark = Color(0xFF9E7C38);
  static const Color goldGlow = Color(0x33C5A059);

  // --- Light Theme (Vintage Parchment & Consular Paper) ---
  static const Color parchmentBackground = Color(0xFFF8F5EE);
  static const Color parchmentCard = Color(0xFFEFE9DA);
  static const Color parchmentElevated = Color(0xFFFFFFFF);
  static const Color parchmentBorder = Color(0xFFD8CFBC);
  static const Color parchmentDivider = Color(0xFFCFC4AF);
  static const Color textLightPrimary = Color(0xFF241C15); // Contrast > 12:1 against parchment
  static const Color textLightSecondary = Color(0xFF5A4D3E);
  static const Color textLightMuted = Color(0xFF867664);

  // --- Dark Theme (Night Flight & Midnight Slate Leather) ---
  static const Color darkBackground = Color(0xFF0F131C);
  static const Color darkCard = Color(0xFF171E2B);
  static const Color darkElevated = Color(0xFF222B3D);
  static const Color darkBorder = Color(0xFF2C384E);
  static const Color darkDivider = Color(0xFF374660);
  static const Color textDarkPrimary = Color(0xFFF3F6FA); // Contrast > 14:1 against darkBackground
  static const Color textDarkSecondary = Color(0xFF9FB0C8);
  static const Color textDarkMuted = Color(0xFF6D7D95);

  // --- Consular Stamp Inks (Light Theme) ---
  static const Color stampCrimsonLight = Color(0xFF9E2A2B); // Entry / Departure
  static const Color stampCobaltLight = Color(0xFF1D3557);  // Immigration
  static const Color stampEmeraldLight = Color(0xFF15803D); // Customs Cleared
  static const Color stampAmberLight = Color(0xFFB45309);   // Transit / Warning
  static const Color stampPurpleLight = Color(0xFF6B21A8);  // Diplomatic

  // --- Consular Stamp Inks (Dark Theme) ---
  static const Color stampCrimsonDark = Color(0xFFF87171);
  static const Color stampCobaltDark = Color(0xFF38BDF8);
  static const Color stampEmeraldDark = Color(0xFF4ADE80);
  static const Color stampAmberDark = Color(0xFFFBBF24);
  static const Color stampPurpleDark = Color(0xFFC084FC);

  // --- Bag Category Accent Colors ---
  static const Color bagPersonal = Color(0xFF0284C7); // Sky blue
  static const Color bagCarryOn = Color(0xFF16A34A);  // Emerald
  static const Color bagChecked = Color(0xFFD97706);  // Amber
}
