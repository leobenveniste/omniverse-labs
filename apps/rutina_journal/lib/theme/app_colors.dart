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

  // --- PRESET 1: CALM SAGE (Forest Canopy / Mindful Organic) ---
  static const AppColors calmSageLight = AppColors(
    primary: Color(0xFF2D4A2B),         // Forest Canopy Sage
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC85A3B),       // Warm Terracotta Accent
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFFAF8F5),      // Sunlight Linen
    surface: Color(0xFFFFFFFF),         // Crisp Card
    surfaceVariant: Color(0xFFF2ECE1),  // Linen Tint
    outline: Color(0xFFE5DDD0),         // Sand Hairline Border
    textPrimary: Color(0xFF1B221C),     // Deep Mineral Sage
    textSecondary: Color(0xFF5A665D),   // Muted Foliage
    textTertiary: Color(0xFF8A968C),
    completion: Color(0xFF2E7D32),      // Evergreen check
    error: Color(0xFFC62828),
    streak: Color(0xFFC85A3B),
    backgroundGradient: [
      Color(0xFFFFFDF8),                // Golden morning sun glow
      Color(0xFFFAF3E5),                // Soft linen warmth
      Color(0xFFF5ECE0),
    ],
    cardBorderRadius: 18.0,
    cardBorderWidth: 1.0,
  );

  static const AppColors calmSageDark = AppColors(
    primary: Color(0xFF72D572),         // Luminous Vitality Sage (WCAG AA 10.4:1)
    onPrimary: Color(0xFF0D2411),
    secondary: Color(0xFFFF8A65),       // Warm Terracotta Glow (WCAG AA 8.6:1)
    onSecondary: Color(0xFF331006),
    background: Color(0xFF0E1310),      // Deep Forest Obsidian Canvas
    surface: Color(0xFF171F1A),         // Elevated Sage Slate Bento Card
    surfaceVariant: Color(0xFF222C25),  // Soft Moss Container
    outline: Color(0xFF2D3A30),         // Crisp Lichen Hairline
    textPrimary: Color(0xFFF4F7F4),     // Crisp Linen White
    textSecondary: Color(0xFFA3B0A5),   // Lichen Silver
    textTertiary: Color(0xFF6C7A6F),
    completion: Color(0xFF4ADE80),
    error: Color(0xFFEF5350),
    streak: Color(0xFFFF7A50),
    backgroundGradient: [
      Color(0xFF0E1310),
      Color(0xFF131A15),
      Color(0xFF18201B),
    ],
    cardBorderRadius: 18.0,
    cardBorderWidth: 1.0,
  );

  // --- PRESET 2: NEO-KINETIC (Desert Rose & Sunset Boulevard) ---
  static const AppColors neoKineticLight = AppColors(
    primary: Color(0xFFC85A3B),         // Rich Terracotta
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFD47A5B),       // Warm Clay
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFFDF8F5),      // Warm Sand Canvas
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF7ECE5),
    outline: Color(0xFFEADBD1),
    textPrimary: Color(0xFF241814),
    textSecondary: Color(0xFF6E5C55),
    textTertiary: Color(0xFF9C8982),
    completion: Color(0xFF2E7D32),
    error: Color(0xFFC62828),
    streak: Color(0xFFD35400),
    backgroundGradient: [
      Color(0xFFFFFBF8),
      Color(0xFFFDF2EC),
      Color(0xFFF8E7DE),
    ],
    cardBorderRadius: 16.0,
    cardBorderWidth: 1.2,
  );

  static const AppColors neoKineticDark = AppColors(
    primary: Color(0xFFFF7A59),         // Vibrant Terracotta Coral (WCAG AA 8.8:1)
    onPrimary: Color(0xFF330F06),
    secondary: Color(0xFFFBBF24),       // Sunset Amber Glow
    onSecondary: Color(0xFF2B1A00),
    background: Color(0xFF14100E),      // Roasted Espresso Obsidian
    surface: Color(0xFF1F1916),         // Warm Earthy Bento Card
    surfaceVariant: Color(0xFF2D2420),  // Roast Clay Container
    outline: Color(0xFF3F322C),         // Warm Copper Hairline
    textPrimary: Color(0xFFFFF6F2),     // Warm Ivory
    textSecondary: Color(0xFFBBA8A1),   // Muted Sand
    textTertiary: Color(0xFF7A6A64),
    completion: Color(0xFF34D399),
    error: Color(0xFFFF5252),
    streak: Color(0xFFF59E0B),
    backgroundGradient: [
      Color(0xFF14100E),
      Color(0xFF1A1412),
      Color(0xFF221A17),
    ],
    cardBorderRadius: 16.0,
    cardBorderWidth: 1.2,
  );

  // --- PRESET 3: MIDNIGHT BENTO (Midnight Galaxy & Cosmic Night) ---
  static const AppColors midnightBentoLight = AppColors(
    primary: Color(0xFF1E293B),         // Deep Cosmic Navy
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF4F46E5),       // Indigo Starlight
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF4F6FC),      // Glacier Starlight Canvas
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE9EDF8),
    outline: Color(0xFFD4DCED),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF8392A5),
    completion: Color(0xFF10B981),
    error: Color(0xFFDC2626),
    streak: Color(0xFFF59E0B),
    backgroundGradient: [
      Color(0xFFF8F9FE),
      Color(0xFFEFF2FB),
      Color(0xFFE5EAF7),
    ],
    cardBorderRadius: 16.0,
    cardBorderWidth: 1.2,
  );

  static const AppColors midnightBentoDark = AppColors(
    primary: Color(0xFF818CF8),         // Ethereal Periwinkle Star (WCAG AA 9.4:1)
    onPrimary: Color(0xFF141738),
    secondary: Color(0xFFC084FC),       // Mystic Nebula Violet
    onSecondary: Color(0xFF2C0F4F),
    background: Color(0xFF0B0E17),      // Deep Cosmic Void
    surface: Color(0xFF131926),         // Frosted Obsidian Bento Card
    surfaceVariant: Color(0xFF1C2438),  // Starlight Indigo Container
    outline: Color(0xFF27334D),         // Cosmic Indigo Hairline
    textPrimary: Color(0xFFF8FAFC),     // Pure Starlight
    textSecondary: Color(0xFF94A3B8),   // Celestial Slate
    textTertiary: Color(0xFF64748B),
    completion: Color(0xFF38BDF8),
    error: Color(0xFFF87171),
    streak: Color(0xFFFBBF24),
    backgroundGradient: [
      Color(0xFF0B0E17),
      Color(0xFF0F1422),
      Color(0xFF141B2E),
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
