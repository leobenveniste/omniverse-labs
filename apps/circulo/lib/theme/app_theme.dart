import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupRoleColors {
  static const Color organizer = Color(0xFF06B6D4); // 🎯 Cyan
  static const Color connector = Color(0xFFF43F5E); // 💬 Coral
  static const Color explorer = Color(0xFF10B981);  // 🧭 Emerald
  static const Color chill = Color(0xFFA78BFA);     // ☕ Soft Purple

  static Color getColor(String role) {
    switch (role) {
      case 'organizer':
        return organizer;
      case 'connector':
        return connector;
      case 'explorer':
        return explorer;
      case 'chill':
      default:
        return chill;
    }
  }
}

class AppTheme {
  // --- Colores Principales M3 Expressive ---
  static const Color electricViolet = Color(0xFF7C3AED); // Primario Oficial (#7C3AED)
  static const Color deepViolet = Color(0xFF6D28D9);     // Primario Light
  static const Color violetLight = Color(0xFFDDD6FE);
  static const Color vibrantCoral = Color(0xFFF43F5E);   // Secundario K4 Oficial (#F43F5E)
  static const Color crimsonCoral = Color(0xFFE11D48);   // Secundario Light
  static const Color warmAmber = Color(0xFFF59E0B);      // Terciario Oficial / Círculo Plus (#F59E0B)
  static const Color richAmber = Color(0xFFD97706);
  static const Color emeraldMint = Color(0xFF10B981);    // Éxito / Asistencia confirmada
  static const Color emeraldDark = Color(0xFF059669);
  static const Color errorRed = Color(0xFFF43F5E);

  // --- Capas de Superficie Oscura (Onyx Deep & Dark Surface) ---
  static const Color darkBackground = Color(0xFF0F0D15); // Onyx Deep Oficial
  static const Color darkSurface = Color(0xFF1A1625);    // Surface Cards & Diálogos
  static const Color darkCard = Color(0xFF1A1625);
  static const Color surfaceElevated = Color(0xFF231E32);// Inputs y chips elevados
  static const Color darkBorder = Color(0xFF2E2842);     // Borde sutil
  static const Color borderHighlight = Color(0xFF4C1D95);

  // --- Capas de Superficie Clara (Off-White Warm) ---
  static const Color lightBackground = Color(0xFFFAF9FC);// Off-White Warm Oficial
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF3F2F8);
  static const Color lightBorder = Color(0xFFE5E3ED);
  static const Color lightBorderHighlight = Color(0xFFD1CFDF);

  // --- Tipografía y Textos (WCAG AA Compliant > 4.5:1) ---
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF374151);
  static const Color lightTextMuted = Color(0xFF6B7280);

  // --- Helpers Semánticos Adaptativos ---
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryColor(BuildContext context) =>
      isDark(context) ? electricViolet : deepViolet;

  static Color secondaryColor(BuildContext context) =>
      isDark(context) ? vibrantCoral : crimsonCoral;

  static Color tertiaryColor(BuildContext context) =>
      isDark(context) ? warmAmber : richAmber;

  static Color onPrimaryColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF121212) : Colors.white;

  static Color surfaceContainer(BuildContext context) =>
      isDark(context) ? surfaceElevated : lightSurfaceElevated;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color textPrimaryColor(BuildContext context) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  static Color textMutedColor(BuildContext context) =>
      isDark(context) ? textMuted : lightTextMuted;

  /// Estilo estandarizado M3 Expressive para botones de acción en el Header
  static ButtonStyle headerActionButtonStyle(
    BuildContext context, {
    bool isFilled = true,
    Color? accentColor,
  }) {
    final dark = isDark(context);
    final primary = accentColor ?? (dark ? electricViolet : deepViolet);
    final onPrimary = accentColor != null
        ? Colors.white
        : (dark ? const Color(0xFF121212) : Colors.white);
    final disabledBg =
        (dark ? surfaceElevated : lightSurfaceElevated).withValues(alpha: 0.6);
    final disabledFg = (dark ? textMuted : lightTextMuted);

    if (isFilled) {
      return ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return StadiumBorder(
              side: BorderSide(
                color: dark ? Colors.white : lightTextPrimary,
                width: 2,
              ),
            );
          }
          return const StadiumBorder();
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledBg;
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: 0.85);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.92);
          }
          return primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledFg;
          return onPrimary;
        }),
        elevation: const WidgetStatePropertyAll(0),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
    } else {
      return ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: WidgetStateProperty.resolveWith((states) {
          final width = states.contains(WidgetState.focused) ? 2.0 : 1.5;
          final color = states.contains(WidgetState.disabled)
              ? (dark ? darkBorder : lightBorder)
              : primary;
          return StadiumBorder(side: BorderSide(color: color, width: width));
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.transparent;
          if (states.contains(WidgetState.pressed)) {
            return primary.withValues(alpha: 0.20);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.14);
          }
          return primary.withValues(alpha: 0.10);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return disabledFg;
          return primary;
        }),
        elevation: const WidgetStatePropertyAll(0),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
    }
  }

  /// Estilo M3 Expressive para botones de ícono en el Header
  static ButtonStyle headerIconButtonStyle(
    BuildContext context, {
    Color? foregroundColor,
  }) {
    final dark = isDark(context);
    final fg = foregroundColor ?? (dark ? electricViolet : deepViolet);

    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return fg.withValues(alpha: 0.16);
        }
        if (states.contains(WidgetState.hovered)) {
          return fg.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return dark ? textMuted : lightTextMuted;
        }
        return fg;
      }),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStateProperty.resolveWith((states) {
        final isFocused = states.contains(WidgetState.focused);
        return CircleBorder(
          side: isFocused ? BorderSide(color: fg, width: 2.0) : BorderSide.none,
        );
      }),
    );
  }

  static SystemUiOverlayStyle systemOverlayStyleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: electricViolet,
        onPrimary: Color(0xFF121212),
        primaryContainer: Color(0xFF4C1D95),
        onPrimaryContainer: violetLight,
        secondary: vibrantCoral,
        onSecondary: Color(0xFF121212),
        tertiary: warmAmber,
        surface: darkSurface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceContainerHighest: surfaceElevated,
        outline: darkBorder,
        outlineVariant: darkBorder,
        error: errorRed,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 16,
        actionsPadding: const EdgeInsets.only(right: 12),
        systemOverlayStyle: systemOverlayStyleFor(Brightness.dark),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: electricViolet, size: 22),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: darkBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: electricViolet.withValues(alpha: 0.22),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? electricViolet : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: isSelected ? electricViolet : textSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: electricViolet, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buildPrimaryButtonStyle(
          primary: electricViolet,
          onPrimary: const Color(0xFF121212),
          disabledBg: surfaceElevated,
          disabledFg: textMuted,
          focusBorderColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buildPrimaryButtonStyle(
          primary: electricViolet,
          onPrimary: const Color(0xFF121212),
          disabledBg: surfaceElevated,
          disabledFg: textMuted,
          focusBorderColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buildOutlinedButtonStyle(
          primary: electricViolet,
          border: darkBorder,
          disabledFg: textMuted,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: electricViolet.withValues(alpha: 0.2),
        side: const BorderSide(color: darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: deepViolet,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEDE9FE),
        onPrimaryContainer: deepViolet,
        secondary: crimsonCoral,
        onSecondary: Colors.white,
        tertiary: richAmber,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        surfaceContainerHighest: lightSurfaceElevated,
        outline: lightBorder,
        outlineVariant: lightBorder,
        error: errorRed,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 16,
        actionsPadding: const EdgeInsets.only(right: 12),
        systemOverlayStyle: systemOverlayStyleFor(Brightness.light),
        titleTextStyle: const TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: deepViolet, size: 22),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: lightBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: deepViolet.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? deepViolet : lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: isSelected ? deepViolet : lightTextSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: lightTextMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepViolet, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buildPrimaryButtonStyle(
          primary: deepViolet,
          onPrimary: Colors.white,
          disabledBg: lightSurfaceElevated,
          disabledFg: lightTextMuted,
          focusBorderColor: lightTextPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buildPrimaryButtonStyle(
          primary: deepViolet,
          onPrimary: Colors.white,
          disabledBg: lightSurfaceElevated,
          disabledFg: lightTextMuted,
          focusBorderColor: lightTextPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buildOutlinedButtonStyle(
          primary: deepViolet,
          border: lightBorder,
          disabledFg: lightTextMuted,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: const TextStyle(
          color: lightTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceElevated,
        selectedColor: deepViolet.withValues(alpha: 0.15),
        side: const BorderSide(color: lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: lightTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
    );
  }

  static ButtonStyle _buildPrimaryButtonStyle({
    required Color primary,
    required Color onPrimary,
    required Color disabledBg,
    required Color disabledFg,
    required Color focusBorderColor,
  }) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledBg;
        if (states.contains(WidgetState.pressed)) {
          return primary.withValues(alpha: 0.85);
        }
        if (states.contains(WidgetState.hovered)) {
          return primary.withValues(alpha: 0.92);
        }
        return primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledFg;
        return onPrimary;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return onPrimary.withValues(alpha: 0.12);
        }
        return null;
      }),
      shape: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: focusBorderColor, width: 2),
          );
        }
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        );
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return 0;
        if (states.contains(WidgetState.hovered)) return 2;
        return 0;
      }),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  static ButtonStyle _buildOutlinedButtonStyle({
    required Color primary,
    required Color border,
    required Color disabledFg,
  }) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabledFg;
        return primary;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return primary.withValues(alpha: 0.14);
        }
        if (states.contains(WidgetState.hovered)) {
          return primary.withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: border.withValues(alpha: 0.5), width: 1);
        }
        if (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return BorderSide(color: primary, width: 2);
        }
        return BorderSide(color: border, width: 1.5);
      }),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
