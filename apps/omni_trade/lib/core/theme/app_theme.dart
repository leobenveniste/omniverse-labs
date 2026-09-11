import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme({required bool isDark}) {
    final colors = isDark ? AppColors.dark : AppColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.loss,
        onError: colors.onLoss,
        outline: colors.outline,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: AppTypography.title(colors.textPrimary),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colors.outline, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: colors.outline, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTypography.body(colors.textTertiary),
        labelStyle: AppTypography.body(colors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: colors.outline, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: colors.outline, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: colors.loss, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: AppSpacing.paddingButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: AppTypography.body(colors.onPrimary, isBold: true),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.outline, width: 1.0),
          padding: AppSpacing.paddingButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: AppTypography.body(colors.textPrimary, isMedium: true),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outline,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}

/// Helper extension on BuildContext to quickly access tokens.
extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  AppColors get colors => isDarkMode ? AppColors.dark : AppColors.light;
}
