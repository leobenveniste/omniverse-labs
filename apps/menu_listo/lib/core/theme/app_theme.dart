import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_theme_types.dart';

class AppTheme {
  static ThemeData buildTheme(AppDesignTheme designTheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (designTheme) {
      case AppDesignTheme.modernBotanical:
        return _buildBotanicalTheme(isDark);
      case AppDesignTheme.editorialGourmet:
        return _buildGourmetTheme(isDark);
      case AppDesignTheme.materialYouBento:
        return _buildBentoTheme(isDark);
    }
  }

  // --- 1. MODERN BOTANICAL (Olive, Sage, Terracotta, 20px Rounded Curves) ---
  static ThemeData _buildBotanicalTheme(bool isDark) {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: isDark ? AppColors.botanicalPrimaryDark : AppColors.botanicalPrimaryLight,
      onPrimary: isDark ? AppColors.botanicalOnPrimaryDark : AppColors.botanicalOnPrimaryLight,
      secondary: isDark ? AppColors.botanicalSecondaryDark : AppColors.botanicalSecondaryLight,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.botanicalAccentDark : AppColors.botanicalAccentLight,
      onTertiary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: isDark ? AppColors.botanicalSurfaceDark : AppColors.botanicalSurfaceLight,
      onSurface: isDark ? AppColors.botanicalOnSurfaceDark : AppColors.botanicalOnSurfaceLight,
      surfaceContainerLowest: isDark ? const Color(0xFF0E130D) : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? const Color(0xFF181F16) : const Color(0xFFF3F6F0),
      surfaceContainer: isDark ? const Color(0xFF1D241A) : const Color(0xFFEDF2EA),
      surfaceContainerHigh: isDark ? const Color(0xFF222B1E) : const Color(0xFFE7ECE4),
      surfaceContainerHighest: isDark ? AppColors.botanicalSurfaceVariantDark : AppColors.botanicalSurfaceVariantLight,
      secondaryContainer: isDark ? const Color(0xFF2E3D26) : const Color(0xFFD6E7CA),
      onSecondaryContainer: isDark ? const Color(0xFFC7E6B8) : const Color(0xFF213715),
      onSurfaceVariant: isDark ? const Color(0xFFB0B9A8) : const Color(0xFF5E6754),
      outline: isDark ? const Color(0xFF4A5443) : const Color(0xFFD0D8C8),
    );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.botanicalBackgroundDark : AppColors.botanicalBackgroundLight,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          height: 1.5,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.6), width: 1),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  // --- 2. EDITORIAL GOURMET (Luxury Charcoal, Bronze, Wine, 6px Crisp Sharp Corners) ---
  static ThemeData _buildGourmetTheme(bool isDark) {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: isDark ? AppColors.gourmetPrimaryDark : AppColors.gourmetPrimaryLight,
      onPrimary: isDark ? AppColors.gourmetOnPrimaryDark : AppColors.gourmetOnPrimaryLight,
      secondary: isDark ? AppColors.gourmetSecondaryDark : AppColors.gourmetSecondaryLight,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.gourmetAccentDark : AppColors.gourmetAccentLight,
      onTertiary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: isDark ? AppColors.gourmetSurfaceDark : AppColors.gourmetSurfaceLight,
      onSurface: isDark ? AppColors.gourmetOnSurfaceDark : AppColors.gourmetOnSurfaceLight,
      surfaceContainerLowest: isDark ? const Color(0xFF0F0E0D) : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? const Color(0xFF181514) : const Color(0xFFF7F2EC),
      surfaceContainer: isDark ? const Color(0xFF1E1A18) : const Color(0xFFF1EAE1),
      surfaceContainerHigh: isDark ? const Color(0xFF26211E) : const Color(0xFFEAE2D7),
      surfaceContainerHighest: isDark ? AppColors.gourmetSurfaceVariantDark : AppColors.gourmetSurfaceVariantLight,
      secondaryContainer: isDark ? const Color(0xFF45382B) : const Color(0xFFEFE2CF),
      onSecondaryContainer: isDark ? const Color(0xFFF3DEC4) : const Color(0xFF382917),
      onSurfaceVariant: isDark ? const Color(0xFFC0B7AE) : const Color(0xFF6B625B),
      outline: isDark ? const Color(0xFF473E38) : const Color(0xFFE2D7CB),
    );

    final baseTextTheme = GoogleFonts.loraTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.gourmetBackgroundDark : AppColors.gourmetBackgroundLight,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.lora(
          fontSize: 16,
          height: 1.6,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.lora(
          fontSize: 14,
          height: 1.5,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // Sharp luxury corners
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: colorScheme.outline),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: GoogleFonts.lora(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: colorScheme.secondary, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colorScheme.secondary, width: 2),
        ),
      ),
    );
  }

  // --- 3. MATERIAL YOU TECH BENTO (Electric Avocado, Mint, Amber, 28px Chunky Bento Curves) ---
  static ThemeData _buildBentoTheme(bool isDark) {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: isDark ? AppColors.bentoPrimaryDark : AppColors.bentoPrimaryLight,
      onPrimary: isDark ? AppColors.bentoOnPrimaryDark : AppColors.bentoOnPrimaryLight,
      secondary: isDark ? AppColors.bentoSecondaryDark : AppColors.bentoSecondaryLight,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.bentoAccentDark : AppColors.bentoAccentLight,
      onTertiary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: isDark ? AppColors.bentoSurfaceDark : AppColors.bentoSurfaceLight,
      onSurface: isDark ? AppColors.bentoOnSurfaceDark : AppColors.bentoOnSurfaceLight,
      surfaceContainerLowest: isDark ? const Color(0xFF0B110C) : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark ? const Color(0xFF121B14) : const Color(0xFFEDF4E9),
      surfaceContainer: isDark ? const Color(0xFF17241A) : const Color(0xFFE4EDE0),
      surfaceContainerHigh: isDark ? const Color(0xFF1D2D21) : const Color(0xFFDCE7D8),
      surfaceContainerHighest: isDark ? AppColors.bentoSurfaceVariantDark : AppColors.bentoSurfaceVariantLight,
      secondaryContainer: isDark ? const Color(0xFF283B2B) : const Color(0xFFD3E4CE),
      onSecondaryContainer: isDark ? const Color(0xFFBCE1B6) : const Color(0xFF1B2F1F),
      onSurfaceVariant: isDark ? const Color(0xFFA5B8A6) : const Color(0xFF485849),
      outline: isDark ? const Color(0xFF384A3B) : const Color(0xFFCCE0CA),
    );

    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.bentoBackgroundDark : AppColors.bentoBackgroundLight,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          height: 1.4,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          height: 1.4,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // Bold Bento Curves
          side: BorderSide(color: colorScheme.outline, width: 1.8),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.5),
        ),
      ),
    );
  }
}
