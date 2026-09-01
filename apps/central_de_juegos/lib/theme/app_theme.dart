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

  static ThemeData lightTheme = darkTheme; // Defaulting to the new cyber aesthetic
}
