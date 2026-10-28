import 'package:flutter/material.dart';

class AppColors {
  // --- CIVIC DELTA HORIZON PALETTE (Aqua Mist & Nocturnal Inversion) ---

  // Light Primary (Deep Oceanic Delta / Azul Náutico Isleño)
  static const Color primary = Color(0xFF05375A);
  static const Color primaryContainer = Color(0xFF145380);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFCDE8F8);
  static const Color primaryFixed = Color(0xFFD0E4ED);
  static const Color primaryFixedDim = Color(0xFFB5D7E8);
  static const Color onPrimaryFixed = Color(0xFF001F35);
  static const Color onPrimaryFixedVariant = Color(0xFF0B436D);

  // Light Secondary (Delta Reed Emerald / Verde Juncal Isleño)
  static const Color secondary = Color(0xFF007D54);
  static const Color secondaryEmerald = Color(0xFF059669);
  static const Color secondaryContainer = Color(0xFF9EF2D0);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF003823);
  static const Color secondaryFixed = Color(0xFFA6F7D5);
  static const Color secondaryFixedDim = Color(0xFF70E7BA);

  // Light Tertiary (Paraná Sunset Coral / Atardecer Isleño)
  static const Color tertiary = Color(0xFFD65522);
  static const Color tertiaryContainer = Color(0xFFFFDACF);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF3E1204);
  static const Color tertiaryFixed = Color(0xFFFFDBD1);
  static const Color tertiaryFixedDim = Color(0xFFFFB5A0);

  // Safety & Emergency (SOS / COD)
  static const Color emergency = Color(0xFFBA1A1A);
  static const Color emergencyContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color emergencyLight = Color(0xFFEF4444);
  static const Color emergencyDark = Color(0xFF991B1B);

  // Surfaces & Backgrounds (Light - Aqua Mist Canvas #d0e4ed)
  static const Color background = Color(0xFFD0E4ED); // Brisa del Delta canvas
  static const Color surface = Color(0xFFD0E4ED);
  static const Color surfaceDim = Color(0xFFBED8E5);
  static const Color surfaceBright = Color(0xFFE8F3F8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Crisp floating cards
  static const Color surfaceContainerLow = Color(0xFFE3EFF6);
  static const Color surfaceContainer = Color(0xFFD0E4ED);
  static const Color surfaceContainerHigh = Color(0xFFBFDBE8);
  static const Color surfaceContainerHighest = Color(0xFFAFD0DF);

  // Dark Palette Tokens (Inverted Oceanic Abyss / Nocturna Fluvial)
  static const Color darkBackground = Color(0xFF06131E); // Deep maritime abyss
  static const Color darkSurface = Color(0xFF0B1B29);
  static const Color darkSurfaceLow = Color(0xFF081622);
  static const Color darkSurfaceContainer = Color(0xFF102436); // Elevated dark cards
  static const Color darkSurfaceHigh = Color(0xFF173148);
  static const Color darkCardBorder = Color(0xFF22486A);
  static const Color darkPrimary = Color(0xFF62CEF7); // Electric Aqua Mist (Inverted Hero)
  static const Color darkSecondary = Color(0xFF3CE9A5); // Bioluminescent River Emerald
  static const Color darkTertiary = Color(0xFFFF8D69); // Luminous River Sunset
  static const Color darkSurfaceContainerHigh = Color(0xFF173148);
  static const Color darkSurfaceContainerHighest = Color(0xFF1F3E5A);
  static const Color darkOnSurface = Color(0xFFE6F3FA); // Glacial Ice White
  static const Color darkOnSurfaceVariant = Color(0xFFA8C7DB);
  static const Color darkOnSurfaceMuted = Color(0xFF6D94AF);

  // Outlines & Borders
  static const Color outline = Color(0xFF608299);
  static const Color outlineVariant = Color(0xFFB8D5E5);
  static const Color cardBorder = Color(0xFFB8D5E5);

  // Typography & On-Surface Tokens (Light)
  static const Color onSurface = Color(0xFF0A2337); // Deep oceanic slate
  static const Color onSurfaceVariant = Color(0xFF2D485C);
  static const Color onSurfaceMuted = Color(0xFF506E84);
  static const Color onSurfaceSubtle = Color(0xFF7597AF);

  // Compatibility aliases
  static const Color primaryDark = Color(0xFF03223A);
  static const Color primaryLight = Color(0xFF145380);
  static const Color secondaryLight = Color(0xFF059669);
  static const Color accent = Color(0xFF007D54);
  static const Color accentLight = Color(0xFF3CE9A5);
  static const Color surfaceVariant = Color(0xFFBFDBE8);

  // Helpers to resolve theme-adaptive colors
  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : background;
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceContainer : surfaceContainerLowest;
  static Color onSurfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOnSurface : onSurface;
  static Color onSurfaceVariantOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOnSurfaceVariant : onSurfaceVariant;
  static Color onSurfaceMutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOnSurfaceMuted : onSurfaceMuted;
  static Color primaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkPrimary : primary;
  static Color secondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSecondary : secondary;
  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCardBorder : cardBorder;
}
