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
  final List<Color> backgroundGradient;
  final double cardBorderRadius;
  final double cardBorderWidth;

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
    required this.backgroundGradient,
    this.cardBorderRadius = 16.0,
    this.cardBorderWidth = 1.0,
  });

  // --- PRESET 1: CALM SAGE & COZY SUNSHINE (Mindful / Warm Organic) ---
  static const AppColors calmSageLight = AppColors(
    primary: Color(0xFF234E35),         // Deep Forest Sage
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC85A3B),       // Warm Terracotta
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFFBF8F1),      // Warm Sunlight Linen
    surface: Color(0xFFFFFFFF),         // Crisp Card
    surfaceVariant: Color(0xFFF4ECE0),  // Warm Sunlight Tint
    outline: Color(0xFFE8DECF),         // Soft Sand Border
    textPrimary: Color(0xFF1E211E),     // Deep Mineral Charcoal
    textSecondary: Color(0xFF5E655F),   // Muted Sage Slate
    textTertiary: Color(0xFF919992),
    completion: Color(0xFF2E7D32),      // Evergreen check
    error: Color(0xFFC62828),
    streak: Color(0xFFD35400),
    backgroundGradient: [
      Color(0xFFFFFDF8),                // Golden morning sun glow
      Color(0xFFFAF3E5),                // Soft linen warmth
      Color(0xFFF5ECE0),
    ],
    cardBorderRadius: 20.0,
    cardBorderWidth: 1.0,
  );

  static const AppColors calmSageDark = AppColors(
    primary: Color(0xFF81C784),         // Soft Sage Glow
    onPrimary: Color(0xFF0F2617),
    secondary: Color(0xFFFF8A65),       // Soft Terracotta Glow
    onSecondary: Color(0xFF2C1008),
    background: Color(0xFF151816),      // Deep Organic Charcoal
    surface: Color(0xFF1D221E),         // Elevated Matte Surface
    surfaceVariant: Color(0xFF262C28),
    outline: Color(0xFF313833),
    textPrimary: Color(0xFFF4F6F4),     // Crisp Off-White
    textSecondary: Color(0xFFA5ACA6),   // Soft Silver
    textTertiary: Color(0xFF6B726C),
    completion: Color(0xFF4CAF50),
    error: Color(0xFFEF5350),
    streak: Color(0xFFFF7043),
    backgroundGradient: [
      Color(0xFF161917),
      Color(0xFF1A1C18),
      Color(0xFF1E1F1B),
    ],
    cardBorderRadius: 20.0,
    cardBorderWidth: 1.0,
  );

  // --- PRESET 2: NEO-KINETIC (High-Momentum / Cyber Sharp) ---
  static const AppColors neoKineticLight = AppColors(
    primary: Color(0xFF00C853),         // Neo Mint
    onPrimary: Color(0xFF002911),
    secondary: Color(0xFFFF6D00),       // Cyber Amber
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFD),      // Cool Crisp Canvas
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE9EEF5),
    outline: Color(0xFFD0D7E2),
    textPrimary: Color(0xFF0A0C10),     // Pitch Ink
    textSecondary: Color(0xFF4C5462),
    textTertiary: Color(0xFF868FA0),
    completion: Color(0xFF00C853),
    error: Color(0xFFD50000),
    streak: Color(0xFFFF6D00),
    backgroundGradient: [
      Color(0xFFFFFFFF),
      Color(0xFFF3F6FA),
      Color(0xFFEBF1F8),
    ],
    cardBorderRadius: 8.0,              // Sharp, athletic corners
    cardBorderWidth: 1.6,              // High-contrast cyber edge
  );

  static const AppColors neoKineticDark = AppColors(
    primary: Color(0xFF00E676),         // Glowing Electric Mint
    onPrimary: Color(0xFF001F0D),
    secondary: Color(0xFFFF9100),       // Electric Solar Amber
    onSecondary: Color(0xFF2E1500),
    background: Color(0xFF08090C),      // Carbon Abyss
    surface: Color(0xFF10131A),         // Elevated Slate Carbon
    surfaceVariant: Color(0xFF191D26),
    outline: Color(0xFF242A38),
    textPrimary: Color(0xFFFFFFFF),     // Pure White
    textSecondary: Color(0xFFA2A8B5),
    textTertiary: Color(0xFF636A78),
    completion: Color(0xFF00E676),
    error: Color(0xFFFF5252),
    streak: Color(0xFFFF9100),
    backgroundGradient: [
      Color(0xFF08090C),
      Color(0xFF0F1218),
      Color(0xFF151922),
    ],
    cardBorderRadius: 8.0,
    cardBorderWidth: 1.6,
  );

  // --- PRESET 3: MIDNIGHT BENTO (Modern Luxury / Slate & Jewel Glass) ---
  static const AppColors midnightBentoLight = AppColors(
    primary: Color(0xFF1565C0),         // Sapphire Jewel
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF6A1B9A),       // Amethyst Jewel
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF3F5FA),      // Platinum Canvas
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE8ECF5),
    outline: Color(0xFFD5DCEB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textTertiary: Color(0xFF9CA3AF),
    completion: Color(0xFF10B981),      // Emerald Glow
    error: Color(0xFFDC2626),
    streak: Color(0xFFF59E0B),
    backgroundGradient: [
      Color(0xFFF7F8FC),
      Color(0xFFEFF2F9),
      Color(0xFFE6EBF5),
    ],
    cardBorderRadius: 16.0,
    cardBorderWidth: 1.2,
  );

  static const AppColors midnightBentoDark = AppColors(
    primary: Color(0xFF38BDF8),         // Electric Sky
    onPrimary: Color(0xFF082F49),
    secondary: Color(0xFFA78BFA),       // Radiant Violet
    onSecondary: Color(0xFF2E1065),
    background: Color(0xFF090D16),      // Deep Midnight Canvas
    surface: Color(0xFF111726),         // Bento Frosted Slate
    surfaceVariant: Color(0xFF1A2236),
    outline: Color(0xFF28344E),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    completion: Color(0xFF34D399),
    error: Color(0xFFF87171),
    streak: Color(0xFFFBBF24),
    backgroundGradient: [
      Color(0xFF090D16),
      Color(0xFF0E1422),
      Color(0xFF131A2D),
    ],
    cardBorderRadius: 16.0,
    cardBorderWidth: 1.2,
  );

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

  // Categories Colors
  static const Color catHealth = Color(0xFF2E7D32);
  static const Color catMind = Color(0xFF1565C0);
  static const Color catProductivity = Color(0xFFE65100);
  static const Color catSleep = Color(0xFF4527A0);
  static const Color catPersonal = Color(0xFFC2185B);
  static const Color catFinance = Color(0xFF00695C);

  // Mood Orb Gradients
  static const List<Color> moodRadiant = [Color(0xFFFFB300), Color(0xFFFF7043)];
  static const List<Color> moodGood = [Color(0xFF26A69A), Color(0xFF66BB6A)];
  static const List<Color> moodNeutral = [Color(0xFFAB47BC), Color(0xFF7E57C2)];
  static const List<Color> moodLow = [Color(0xFF5C6BC0), Color(0xFF42A5F5)];
  static const List<Color> moodDifficult = [Color(0xFF78909C), Color(0xFF546E7A)];
}
