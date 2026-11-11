import 'package:flutter/material.dart';

/// Strict 4px/8px structural spacing scale per UI/UX Pro Max guidelines.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double minTouchTarget = 48.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusPill = 24.0;
}

/// Maps preset icon keys to consistent Material icons across Queue, Flows, and Logbook.
abstract final class DidItIcons {
  static const Map<String, IconData> all = <String, IconData>{
    'check': Icons.check_circle_outline_rounded,
    'pill': Icons.medication_rounded,
    'lock': Icons.lock_outline_rounded,
    'pet': Icons.pets_rounded,
    'plant': Icons.eco_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'home': Icons.home_outlined,
    'wrench': Icons.build_outlined,
    'water': Icons.water_drop_outlined,
    'flow': Icons.account_tree_outlined,
  };

  static IconData resolve(String key) => all[key] ?? Icons.check_circle_outline_rounded;
}

/// High-contrast semantic palette for Dark OLED and Light modes (WCAG AA >= 4.5:1).
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentPrimary,
    required this.onAccentPrimary,
    required this.accentTint,
    required this.warning,
    required this.warningText,
    required this.warningTint,
    required this.danger,
    required this.dangerText,
    required this.dangerTint,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentPrimary;
  final Color onAccentPrimary;
  final Color accentTint;
  final Color warning;
  final Color warningText;
  final Color warningTint;
  final Color danger;
  final Color dangerText;
  final Color dangerTint;

  static const AppPalette dark = AppPalette(
    background: Color(0xFF090B0E),
    surface: Color(0xFF12161C),
    surfaceElevated: Color(0xFF1B212A),
    border: Color(0xFF262F3B),
    textPrimary: Color(0xFFF4F7FA),
    textSecondary: Color(0xFF9AA6B8),
    accentPrimary: Color(0xFF10B981),
    onAccentPrimary: Color(0xFF042217),
    accentTint: Color(0xFF0F2B22),
    warning: Color(0xFFF59E0B),
    warningText: Color(0xFFFDE68A),
    warningTint: Color(0xFF2B200D),
    danger: Color(0xFFFB7185),
    dangerText: Color(0xFFFECDD3),
    dangerTint: Color(0xFF2E121A),
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFEDF1F5),
    border: Color(0xFFD5DCE5),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    accentPrimary: Color(0xFF059669),
    onAccentPrimary: Color(0xFFFFFFFF),
    accentTint: Color(0xFFD1FAE5),
    warning: Color(0xFFD97706),
    warningText: Color(0xFF92400E),
    warningTint: Color(0xFFFEF3C7),
    danger: Color(0xFFE11D48),
    dangerText: Color(0xFF9F1239),
    dangerTint: Color(0xFFFFE4E6),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? dark;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? accentPrimary,
    Color? onAccentPrimary,
    Color? accentTint,
    Color? warning,
    Color? warningText,
    Color? warningTint,
    Color? danger,
    Color? dangerText,
    Color? dangerTint,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      onAccentPrimary: onAccentPrimary ?? this.onAccentPrimary,
      accentTint: accentTint ?? this.accentTint,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      warningTint: warningTint ?? this.warningTint,
      danger: danger ?? this.danger,
      dangerText: dangerText ?? this.dangerText,
      dangerTint: dangerTint ?? this.dangerTint,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      onAccentPrimary: Color.lerp(onAccentPrimary, other.onAccentPrimary, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      warningTint: Color.lerp(warningTint, other.warningTint, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      dangerTint: Color.lerp(dangerTint, other.dangerTint, t)!,
    );
  }
}

/// Strictly 4 type sizes (`28`, `18`, `14`, `12`) and 3 weights (`w400`, `w600`, `w700`).
abstract final class AppTypography {
  static const TextStyle display = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle title = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.4,
  );
}

ThemeData buildDidItTheme([Brightness brightness = Brightness.dark]) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? AppPalette.dark : AppPalette.light;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.accentPrimary,
    onPrimary: palette.onAccentPrimary,
    secondary: palette.warning,
    onSecondary: palette.background,
    error: palette.danger,
    onError: palette.onAccentPrimary,
    surface: palette.surface,
    onSurface: palette.textPrimary,
    outline: palette.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.background,
    dividerColor: palette.border,
    extensions: <ThemeExtension<dynamic>>[palette],
    textTheme: TextTheme(
      headlineMedium: AppTypography.display.copyWith(color: palette.textPrimary),
      titleMedium: AppTypography.title.copyWith(color: palette.textPrimary),
      bodyMedium: AppTypography.body.copyWith(color: palette.textPrimary),
      labelMedium: AppTypography.label.copyWith(color: palette.textSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: palette.accentPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: palette.border),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accentPrimary,
        foregroundColor: palette.onAccentPrimary,
        minimumSize: const Size(88, AppSpacing.minTouchTarget),
        textStyle: AppTypography.label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.textPrimary,
        minimumSize: const Size(88, AppSpacing.minTouchTarget),
        textStyle: AppTypography.label,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),
  );
}
