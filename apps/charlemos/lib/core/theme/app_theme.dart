import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_theme_preset.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme({
    required AppThemePreset preset,
    required bool isDark,
  }) {
    final colors = AppColors.of(preset, isDark);
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        error: colors.error,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.outline,
        surfaceContainerHighest: colors.surfaceVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.section(colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(colors.cardBorderRadius),
          side: BorderSide(color: colors.outline, width: colors.cardBorderWidth),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTypography.body(colors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(colors.cardBorderRadius * 0.75),
          borderSide: BorderSide(color: colors.outline, width: colors.cardBorderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(colors.cardBorderRadius * 0.75),
          borderSide: BorderSide(color: colors.outline, width: colors.cardBorderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(colors.cardBorderRadius * 0.75),
          borderSide: BorderSide(color: colors.primary, width: colors.cardBorderWidth + 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(colors.cardBorderRadius + 4),
          side: BorderSide(color: colors.outline, width: colors.cardBorderWidth),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(colors.cardBorderRadius + 4),
          ),
          side: BorderSide(color: colors.outline, width: colors.cardBorderWidth),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.16),
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colors.primary : colors.textSecondary,
          );
        }),
      ),
    );
  }

  /// Helper to wrap screens with the preset's distinctive sunshine/atmospheric gradient
  static BoxDecoration getAtmosphericBackground(BuildContext context, AppThemePreset preset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(preset, isDark);

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors.backgroundGradient,
        stops: const [0.0, 0.55, 1.0],
      ),
    );
  }
}
