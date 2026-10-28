import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract class AppTheme {
  /// Light Theme: Vintage Parchment Paper with Burgundy & Gold Accents
  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.burgundyBase,
      onPrimary: Colors.white,
      primaryContainer: AppColors.parchmentCard,
      onPrimaryContainer: AppColors.burgundyDeep,
      secondary: AppColors.goldFoil,
      onSecondary: AppColors.burgundyDeep,
      surface: AppColors.parchmentBackground,
      onSurface: AppColors.textLightPrimary,
      error: AppColors.stampCrimsonLight,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.parchmentBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.parchmentBackground,
        foregroundColor: AppColors.burgundyDeep,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.subheadSerif(color: AppColors.burgundyDeep),
      ),
      cardTheme: CardThemeData(
        color: AppColors.parchmentCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.parchmentBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.parchmentDivider,
        thickness: 1,
        space: 16,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.stampEmeraldLight;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.textLightMuted, width: 1.5),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.burgundyBase,
        foregroundColor: AppColors.goldFoilLight,
        elevation: 3,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.parchmentCard,
        selectedItemColor: AppColors.burgundyBase,
        unselectedItemColor: AppColors.textLightMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Dark Theme: "Night Flight" Midnight Slate & Obsidian Leather
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.goldFoil,
      onPrimary: AppColors.darkBackground,
      primaryContainer: AppColors.darkCard,
      onPrimaryContainer: AppColors.goldFoilLight,
      secondary: AppColors.burgundyLight,
      onSecondary: Colors.white,
      surface: AppColors.darkBackground,
      onSurface: AppColors.textDarkPrimary,
      error: AppColors.stampCrimsonDark,
      onError: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.subheadSerif(color: AppColors.textDarkPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 16,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.stampEmeraldDark;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.textDarkMuted, width: 1.5),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.goldFoil,
        foregroundColor: AppColors.darkBackground,
        elevation: 3,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.goldFoil,
        unselectedItemColor: AppColors.textDarkMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
