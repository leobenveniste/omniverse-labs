import 'package:flutter/material.dart';
import 'app_theme_preset.dart';

/// Semantic design tokens for all 3 aesthetic presets in both light and dark modes.
class AppColors {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color completion;
  final Color error;
  final Color streak;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.completion,
    required this.error,
    required this.streak,
  });

  // --- PRESET 1: CALM SAGE (Mindful / Editorial Organic) ---
  static const AppColors calmSageLight = AppColors(
    primary: Color(0xFF234E35),         // Deep Forest Sage
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC85A3B),       // Warm Terracotta
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFFBFBF8),      // Warm Linen / Alabaster
    surface: Color(0xFFFFFFFF),         // Crisp White Card
    surfaceVariant: Color(0xFFF2F0E8),  // Subtle Warm Cream
    outline: Color(0xFFE5E2D8),         // Warm Sand Outline
    textPrimary: Color(0xFF1E211E),     // Deep Mineral Charcoal
    textSecondary: Color(0xFF5E655F),   // Muted Sage Slate
    textTertiary: Color(0xFF919992),
    completion: Color(0xFF2E7D32),      // Evergreen check
    error: Color(0xFFC62828),
    streak: Color(0xFFD35400),
  );

  static const AppColors calmSageDark = AppColors(
    primary: Color(0xFF81C784),         // Soft Sage Glow
    onPrimary: Color(0xFF0F2617),
    secondary: Color(0xFFFF8A65),       // Soft Terracotta Glow
    onSecondary: Color(0xFF2C1008),
    background: Color(0xFF141615),      // Deep Organic Charcoal
    surface: Color(0xFF1B1E1C),         // Elevated Matte Surface
    surfaceVariant: Color(0xFF242926),
    outline: Color(0xFF2D332F),
    textPrimary: Color(0xFFF4F6F4),     // Crisp Off-White
    textSecondary: Color(0xFFA5ACA6),   // Soft Silver
    textTertiary: Color(0xFF6B726C),
    completion: Color(0xFF4CAF50),
    error: Color(0xFFEF5350),
    streak: Color(0xFFFF7043),
  );

  // --- PRESET 2: NEO-KINETIC (High-Momentum / Athletic) ---
  static const AppColors neoKineticLight = AppColors(
    primary: Color(0xFF00C853),         // Neo Mint
    onPrimary: Color(0xFF002911),
    secondary: Color(0xFFFF6D00),       // Cyber Amber
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF8F9FB),      // Cool Crisp White
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFECEFF3),
    outline: Color(0xFFD6DBE2),
    textPrimary: Color(0xFF0F1115),     // Pitch Ink
    textSecondary: Color(0xFF525964),
    textTertiary: Color(0xFF8E95A2),
    completion: Color(0xFF00C853),
    error: Color(0xFFD50000),
    streak: Color(0xFFFF6D00),
  );

  static const AppColors neoKineticDark = AppColors(
    primary: Color(0xFF00E676),         // Glowing Electric Mint
    onPrimary: Color(0xFF001F0D),
    secondary: Color(0xFFFF9100),       // Electric Solar Amber
    onSecondary: Color(0xFF2E1500),
    background: Color(0xFF0A0A0C),      // Carbon Abyss
    surface: Color(0xFF13151A),         // Elevated Slate Carbon
    surfaceVariant: Color(0xFF1C1F27),
    outline: Color(0xFF282C37),
    textPrimary: Color(0xFFFFFFFF),     // Pure White
    textSecondary: Color(0xFFA2A8B5),
    textTertiary: Color(0xFF636A78),
    completion: Color(0xFF00E676),
    error: Color(0xFFFF5252),
    streak: Color(0xFFFF9100),
  );

  // --- PRESET 3: MIDNIGHT BENTO (Modern Luxury / Slate & Jewel) ---
  static const AppColors midnightBentoLight = AppColors(
    primary: Color(0xFF1565C0),         // Sapphire Jewel
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF7B1FA2),       // Amethyst Jewel
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF4F6F9),      // Platinum Slate
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE9EDF3),
    outline: Color(0xFFD2D8E2),
    textPrimary: Color(0xFF10141C),
    textSecondary: Color(0xFF505A6B),
    textTertiary: Color(0xFF8A94A6),
    completion: Color(0xFF00897B),      // Jade Emerald
    error: Color(0xFFC2185B),
    streak: Color(0xFFE65100),
  );

  static const AppColors midnightBentoDark = AppColors(
    primary: Color(0xFF42A5F5),         // Vivid Sapphire Glow
    onPrimary: Color(0xFF082542),
    secondary: Color(0xFFBA68C8),       // Vivid Amethyst Glow
    onSecondary: Color(0xFF2B0A36),
    background: Color(0xFF0D1117),      // Deep Midnight Slate
    surface: Color(0xFF161B22),         // Bento Card Slate
    surfaceVariant: Color(0xFF21262D),
    outline: Color(0xFF30363D),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFF8B949E),
    textTertiary: Color(0xFF535B65),
    completion: Color(0xFF26A69A),
    error: Color(0xFFF06292),
    streak: Color(0xFFFF9800),
  );

  /// Factory helper to resolve active palette by preset and brightness
  static AppColors of(AppThemePreset preset, bool isDark) {
    switch (preset) {
      case AppThemePreset.calmSage:
        return isDark ? calmSageDark : calmSageLight;
      case AppThemePreset.neoKinetic:
        return isDark ? neoKineticDark : neoKineticLight;
      case AppThemePreset.midnightBento:
        return isDark ? midnightBentoDark : midnightBentoLight;
    }
  }

  // Category Accent Colors (Universal across presets)
  static const Color catHealth = Color(0xFF2E7D32);
  static const Color catMind = Color(0xFF7E57C2);
  static const Color catProductivity = Color(0xFFF57C00);
  static const Color catSleep = Color(0xFF3949AB);
  static const Color catPersonal = Color(0xFFD81B60);
  static const Color catFinance = Color(0xFF00897B);

  // Atmospheric Mood Orb Gradients
  static const List<Color> moodRadiant = [Color(0xFFFFB300), Color(0xFFFF7043)];
  static const List<Color> moodGood = [Color(0xFF26A69A), Color(0xFF66BB6A)];
  static const List<Color> moodNeutral = [Color(0xFFAB47BC), Color(0xFF7E57C2)];
  static const List<Color> moodLow = [Color(0xFF5C6BC0), Color(0xFF42A5F5)];
  static const List<Color> moodDifficult = [Color(0xFF78909C), Color(0xFF546E7A)];
}
