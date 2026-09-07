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

  // --- PRESET 1 (DEFAULT): CORAL MIST (Coral Vivo #FF2E3A & Bruma Glacial #DBF6FF) ---
  static const AppColors coralMistLight = AppColors(
    primary: Color(0xFFFF2E3A),         // Coral Vivo
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF0284C7),       // Sky / Ice Accent
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFFAF9F9),      // Crisp Pure Linen
    surface: Color(0xFFFFFFFF),         // Clean Surface
    surfaceVariant: Color(0xFFDBF6FF),  // Bruma Glacial
    outline: Color(0xFFF0D8DB),         // Soft Rose-Slate Hairline
    textPrimary: Color(0xFF1E1416),     // Deep Mineral Espresso
    textSecondary: Color(0xFF6B585C),   // Warm Muted Charcoal
    textTertiary: Color(0xFF9E8A8E),
    completion: Color(0xFF10B981),      // Emerald
    error: Color(0xFFDC2626),
    streak: Color(0xFFFF2E3A),
    backgroundGradient: [
      Color(0xFFFFFFFF),
      Color(0xFFFFF7F8),
      Color(0xFFF5FDFF),
    ],
    cardBorderRadius: 18.0,
    cardBorderWidth: 1.0,
  );

  static const AppColors coralMistDark = AppColors(
    primary: Color(0xFFFF4D58),         // Glowing Coral Red (WCAG AA)
    onPrimary: Color(0xFF260407),
    secondary: Color(0xFF38BDF8),       // Luminous Ice Cyan
    onSecondary: Color(0xFF041E2B),
    background: Color(0xFF120B0D),      // Obsidian Crimson
    surface: Color(0xFF1D1215),         // Elevated Bento Tile
    surfaceVariant: Color(0xFF2A1A1E),  // Deep Wine Container
    outline: Color(0xFF3E242B),         // Rose Gold Hairline
    textPrimary: Color(0xFFFFF5F6),     // Starlight Snow
    textSecondary: Color(0xFFC7AFB4),   // Silver Rose
    textTertiary: Color(0xFF8A7176),
    completion: Color(0xFF34D399),
    error: Color(0xFFEF4444),
    streak: Color(0xFFFF4D58),
    backgroundGradient: [
      Color(0xFF120B0D),
      Color(0xFF180F12),
      Color(0xFF1E1418),
    ],
    cardBorderRadius: 18.0,
    cardBorderWidth: 1.0,
  );

  // --- PRESET 2 (TEMA 1): PLUM ORCHID (Ciruela Profunda #2E0F35 & Orquídea Neón #FF7FEC) ---
  static const AppColors plumOrchidLight = AppColors(
    primary: Color(0xFF5B1B6A),         // Refined Royal Plum
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC026D3),       // Electric Orchid
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFFAF7FC),      // Soft Lilac Mist
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3E8F9),  // Light Orchid Container
    outline: Color(0xFFE5D5EE),
    textPrimary: Color(0xFF240C2B),     // Night Plum
    textSecondary: Color(0xFF6B4875),
    textTertiary: Color(0xFF9E7AA8),
    completion: Color(0xFF10B981),
    error: Color(0xFFDC2626),
    streak: Color(0xFFC026D3),
    backgroundGradient: [
      Color(0xFFFFFFFF),
      Color(0xFFFAF5FD),
      Color(0xFFF5ECFA),
    ],
    cardBorderRadius: 18.0,
    cardBorderWidth: 1.0,
  );

  static const AppColors plumOrchidDark = AppColors(
    primary: Color(0xFFFF7FEC),         // Vibrant Neon Orchid (WCAG AA 8.2:1)
    onPrimary: Color(0xFF2E0F35),
    secondary: Color(0xFFE879F9),       // Luminous Fuchsia
    onSecondary: Color(0xFF2E0F35),
    background: Color(0xFF130617),      // Deep Obsidian Plum
    surface: Color(0xFF210D27),         // Plum Bento Card
    surfaceVariant: Color(0xFF2E0F35),  // Dark Plum Container
    outline: Color(0xFF4C1D57),         // Amethyst Hairline
    textPrimary: Color(0xFFFDF4FF),     // Orchid Starlight
    textSecondary: Color(0xFFD6B3E2),
    textTertiary: Color(0xFF9872A6),
    completion: Color(0xFF34D399),
    error: Color(0xFFF87171),
    streak: Color(0xFFFF7FEC),
    backgroundGradient: [
      Color(0xFF130617),
      Color(0xFF1C0922),
      Color(0xFF240D2C),
    ],
    cardBorderRadius: 18.0,
    cardBorderWidth: 1.0,
  );

  // --- PRESET 3 (TEMA 2): SUNSET SLATE (Mandarina Atardecer #FF9030 & Pizarra Grafito #111827) ---
  static const AppColors sunsetSlateLight = AppColors(
    primary: Color(0xFFEA580C),         // Sunset Orange
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF0F172A),       // Deep Slate
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFFAF8F5),      // Warm Paper
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF4EDE5),  // Sand Container
    outline: Color(0xFFE5DDD3),
    textPrimary: Color(0xFF111827),     // Deep Slate Black
    textSecondary: Color(0xFF4B5563),
    textTertiary: Color(0xFF9CA3AF),
    completion: Color(0xFF10B981),
    error: Color(0xFFDC2626),
    streak: Color(0xFFFF9030),
    backgroundGradient: [
      Color(0xFFFFFFFF),
      Color(0xFFFAF5EE),
      Color(0xFFF5ECE0),
    ],
    cardBorderRadius: 18.0,
    cardBorderWidth: 1.0,
  );

  static const AppColors sunsetSlateDark = AppColors(
    primary: Color(0xFFFF9030),         // Luminous Sunset Orange (WCAG AA 8.4:1)
    onPrimary: Color(0xFF1E0E02),
    secondary: Color(0xFFFBBF24),       // Amber Flare
    onSecondary: Color(0xFF2D1600),
    background: Color(0xFF0B0F17),      // Deep Obsidian Void
    surface: Color(0xFF111827),         // Graphite Slate Bento Card
    surfaceVariant: Color(0xFF1E293B),  // Dark Slate Container
    outline: Color(0xFF283548),         // Graphite Hairline
    textPrimary: Color(0xFFF9FAFB),     // Pure Slate White
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF64748B),
    completion: Color(0xFF34D399),
    error: Color(0xFFF87171),
    streak: Color(0xFFFF9030),
    backgroundGradient: [
      Color(0xFF0B0F17),
      Color(0xFF101622),
      Color(0xFF151D2C),
    ],
    cardBorderRadius: 18.0,
    cardBorderWidth: 1.0,
  );

  static AppColors of(AppThemePreset preset, bool isDark) {
    switch (preset) {
      case AppThemePreset.coralMist:
        return isDark ? coralMistDark : coralMistLight;
      case AppThemePreset.plumOrchid:
        return isDark ? plumOrchidDark : plumOrchidLight;
      case AppThemePreset.sunsetSlate:
        return isDark ? sunsetSlateDark : sunsetSlateLight;
    }
  }
}
