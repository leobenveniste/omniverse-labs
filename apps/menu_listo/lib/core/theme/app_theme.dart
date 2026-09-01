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

  // --- 1. MODERN BOTANICAL THEME ---
  static ThemeData _buildBotanicalTheme(bool isDark) {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: isDark ? AppColors.botanicalPrimaryDark : AppColors.botanicalPrimaryLight,
      onPrimary: isDark ? AppColors.botanicalOnPrimaryDark : AppColors.botanicalOnPrimaryLight,
      secondary: isDark ? AppColors.botanicalSecondaryDark : AppColors.botanicalSecondaryLight,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.botanicalAccentDark : AppColors.botanicalAccentLight,
      onTertiary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: isDark ? AppColors.botanicalSurfaceDark : AppColors.botanicalSurfaceLight,
      onSurface: isDark ? AppColors.botanicalOnSurfaceDark : AppColors.botanicalOnSurfaceLight,
      surfaceContainerHighest: isDark ? AppColors.botanicalSurfaceVariantDark : AppColors.botanicalSurfaceVariantLight,
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
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5), width: 1),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  // --- 2. EDITORIAL GOURMET THEME ---
  static ThemeData _buildGourmetTheme(bool isDark) {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: isDark ? AppColors.gourmetPrimaryDark : AppColors.gourmetPrimaryLight,
      onPrimary: Colors.white,
      secondary: isDark ? AppColors.gourmetSecondaryDark : AppColors.gourmetSecondaryLight,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.gourmetAccentDark : AppColors.gourmetAccentLight,
      onTertiary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: isDark ? AppColors.gourmetSurfaceDark : AppColors.gourmetSurfaceLight,
      onSurface: isDark ? AppColors.gourmetOnSurfaceDark : AppColors.gourmetOnSurfaceLight,
      surfaceContainerHighest: isDark ? AppColors.gourmetSurfaceVariantDark : AppColors.gourmetSurfaceVariantLight,
      onSurfaceVariant: isDark ? const Color(0xFFAEB7AA) : const Color(0xFF565F50),
      outline: isDark ? const Color(0xFF384332) : const Color(0xFFD4DCD0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.gourmetBackgroundDark : AppColors.gourmetBackgroundLight,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.lora(
          fontSize: 16,
          height: 1.6,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline, width: 1.2),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  // --- 3. MATERIAL YOU TECH-CRAFT (Bento) ---
  static ThemeData _buildBentoTheme(bool isDark) {
    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: isDark ? AppColors.bentoPrimaryDark : AppColors.bentoPrimaryLight,
      onPrimary: Colors.white,
      secondary: isDark ? AppColors.bentoSecondaryDark : AppColors.bentoSecondaryLight,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.bentoAccentDark : AppColors.bentoAccentLight,
      onTertiary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: isDark ? AppColors.bentoSurfaceDark : AppColors.bentoSurfaceLight,
      onSurface: isDark ? AppColors.bentoOnSurfaceDark : AppColors.bentoOnSurfaceLight,
      surfaceContainerHighest: isDark ? AppColors.bentoSurfaceVariantDark : AppColors.bentoSurfaceVariantLight,
      onSurfaceVariant: isDark ? const Color(0xFFBCC4B6) : const Color(0xFF4C5547),
      outline: isDark ? const Color(0xFF3F4A39) : const Color(0xFFCAD4C5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.bentoBackgroundDark : AppColors.bentoBackgroundLight,
      textTheme: GoogleFonts.outfitTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
