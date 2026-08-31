import 'package:flutter/material.dart';

class AppTheme {
  // Brand & Accent Colors
  static const Color primaryDark = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF1565C0);

  static const Color trucoGreen = Color(0xFF2E7D32);
  static const Color generalaBurgundy = Color(0xFFC2185B);
  static const Color chinchonAmber = Color(0xFFE65100);
  static const Color unoRed = Color(0xFFD32F2F);
  static const Color burakoBlue = Color(0xFF0277BD);
  static const Color escobaTeal = Color(0xFF00897B);
  static const Color customPurple = Color(0xFF6A1B9A);

  static const List<Color> playerColors = [
    Color(0xFF1E88E5), // Blue
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFFD81B60), // Pink
    Color(0xFFFDD835), // Yellow
    Color(0xFF3949AB), // Indigo
    Color(0xFF00897B), // Teal
    Color(0xFF6D4C41), // Brown
    Color(0xFF546E7A), // Blue Grey
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryLight,
      brightness: Brightness.light,
      surface: const Color(0xFFF8F9FA),
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6F9),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Color(0xFFFFFFFF),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1C1E),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E3E7)),
      ),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E2125),
      surfaceContainerHighest: const Color(0xFF282C34),
    ),
    scaffoldBackgroundColor: const Color(0xFF121417),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Color(0xFF1E2125),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2E333D)),
      ),
      color: const Color(0xFF1E2125),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}
