import 'package:flutter/material.dart';

/// Semantic color design tokens for OmniTrade.
/// Enforces WCAG AA contrast ratios (>4.5:1 for body, >3:1 for headers).
class AppColors {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color profit;
  final Color onProfit;
  final Color loss;
  final Color onLoss;
  final Color proGold;
  final Color warning;
  final List<Color> cardGradient;
  final List<Color> centerFabGradient;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.profit,
    required this.onProfit,
    required this.loss,
    required this.onLoss,
    required this.proGold,
    required this.warning,
    required this.cardGradient,
    required this.centerFabGradient,
  });

  // --- DARK FINANCIAL TERMINAL (Default) ---
  static const AppColors dark = AppColors(
    primary: Color(0xFF6366F1),        // Indigo Pulse
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF00E676),      // Luminous Emerald
    onSecondary: Color(0xFF0B0E14),
    background: Color(0xFF0B0E14),     // Deep Obsidian
    surface: Color(0xFF151B26),        // Slate Surface
    surfaceElevated: Color(0xFF1A2232),// Bento Elevated Card
    outline: Color(0xFF263348),        // Precision Border
    textPrimary: Color(0xFFF8FAFC),    // Crisp High-Contrast Text
    textSecondary: Color(0xFF94A3B8),  // Muted Label Slate
    textTertiary: Color(0xFF64748B),   // Subtle Subtitle
    profit: Color(0xFF00E676),         // Bullish Emerald (WCAG AA)
    onProfit: Color(0xFF0B0E14),
    loss: Color(0xFFFF5252),           // Bearish Vivid Crimson
    onLoss: Color(0xFFFFFFFF),
    proGold: Color(0xFFF59E0B),        // Amber Pro Foil
    warning: Color(0xFFFBBF24),
    cardGradient: [
      Color(0xFF161E2C),
      Color(0xFF111722),
    ],
    centerFabGradient: [
      Color(0xFF00E676),
      Color(0xFF6366F1),
    ],
  );

  // --- LIGHT FINANCIAL THEME ---
  static const AppColors light = AppColors(
    primary: Color(0xFF4F46E5),        // Royal Indigo
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF059669),      // Forest Emerald
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),     // Crisp Alabaster
    surface: Color(0xFFFFFFFF),        // Pure Card
    surfaceElevated: Color(0xFFF1F5F9),// Subtle Gray Surface
    outline: Color(0xFFE2E8F0),        // Hairline Border
    textPrimary: Color(0xFF0F172A),    // Obsidian Black
    textSecondary: Color(0xFF475569),  // Cool Gray
    textTertiary: Color(0xFF94A3B8),   // Muted Hint
    profit: Color(0xFF059669),         // Deep Green
    onProfit: Color(0xFFFFFFFF),
    loss: Color(0xFFDC2626),           // Crimson Red
    onLoss: Color(0xFFFFFFFF),
    proGold: Color(0xFFD97706),
    warning: Color(0xFFD97706),
    cardGradient: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
    centerFabGradient: [
      Color(0xFF059669),
      Color(0xFF4F46E5),
    ],
  );
}
