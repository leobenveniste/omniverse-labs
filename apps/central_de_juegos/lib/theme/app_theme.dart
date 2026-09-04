import 'package:flutter/material.dart';

class AppTheme {
  // Brand & Accent Colors - Cyber Arcade Palette
  static const Color cyberGold = Color(0xFFFFC700);
  static const Color bgDark = Color(0xFF121316);
  static const Color surfaceDark = Color(0xFF18191E);
  static const Color surfaceElevated = Color(0xFF22242B);
  static const Color borderDark = Color(0xFF2A2D36);

  static const Color trucoGreen = Color(0xFF2E7D32);
  static const Color generalaBurgundy = Color(0xFFE65100);
  static const Color diezMilGold = Color(0xFFFFC700);
  static const Color burakoPurple = Color(0xFF7B1FA2);
  static const Color escobaTeal = Color(0xFF00897B);
  static const Color customBlue = Color(0xFF1565C0);

  static const List<Color> playerColors = [
    Color(0xFFFF3B30), // Red
    Color(0xFF007AFF), // Blue
    Color(0xFF34C759), // Green
    Color(0xFFFFCC00), // Yellow/Gold
    Color(0xFFAF52DE), // Purple
    Color(0xFFFF9500), // Orange
    Color(0xFF5AC8FA), // Cyan
    Color(0xFFFF2D55), // Pink
  ];

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: cyberGold,
      onPrimary: Colors.black,
      primaryContainer: surfaceElevated,
      onPrimaryContainer: cyberGold,
      secondary: cyberGold,
      surface: surfaceDark,
      onSurface: Colors.white,
      surfaceContainerHighest: surfaceElevated,
      outline: borderDark,
    ),
    scaffoldBackgroundColor: bgDark,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bgDark,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: cyberGold,
        letterSpacing: 1.0,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderDark, width: 1),
      ),
      color: surfaceDark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cyberGold,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cyberGold,
        side: const BorderSide(color: cyberGold, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cyberGold, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
    ),
  );

  static const Color bgLight = Color(0xFFF6F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFEDF2F7);
  static const Color borderLight = Color(0xFFE2E8F0);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFD9A000), // Slightly deeper gold for contrast on white
      onPrimary: Colors.black,
      primaryContainer: surfaceElevatedLight,
      onPrimaryContainer: Colors.black,
      secondary: Color(0xFFD9A000),
      surface: surfaceLight,
      onSurface: Color(0xFF1A202C),
      surfaceContainerHighest: surfaceElevatedLight,
      outline: borderLight,
    ),
    scaffoldBackgroundColor: bgLight,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bgLight,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1A202C),
        letterSpacing: 1.0,
      ),
      iconTheme: IconThemeData(color: Color(0xFF1A202C)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderLight, width: 1),
      ),
      color: surfaceLight,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Color(0xFFD9A000),
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFFB8860B),
        side: const BorderSide(color: Color(0xFFB8860B), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceElevatedLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFD9A000), width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF718096)),
    ),
  );
}
