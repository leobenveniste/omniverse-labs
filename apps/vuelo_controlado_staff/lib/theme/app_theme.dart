import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // --- Colores Principales: Deep Obsidian & Emerald Mint ---
  static const Color neonGreen = Color(0xFF00E676); // Emerald Mint contemporáneo
  static const Color neonGreenAccent = Color(0xFF10E760);
  static const Color emeraldLight = Color(0xFF69F0AE);
  static const Color emeraldDark = Color(0xFF059669); // Para texto / acentos en modo claro
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color skyBlue = Color(0xFF0EA5E9);
  static const Color amberWarning = Color(0xFFF59E0B);

  // --- Capas de Superficie Oscura (Neutral Dark Gray / Charcoal) ---
  static const Color darkBackground = Color(0xFF121212); // Gris oscuro neutro base
  static const Color darkSurface = Color(0xFF1E1E1E);    // Capa 1: Superficie elevada / Cards
  static const Color darkCard = Color(0xFF242424);       // Capa 1.5: Tarjetas interiores
  static const Color surfaceElevated = Color(0xFF2C2C2C);// Capa 2: Inputs y contenedores
  static const Color darkBorder = Color(0xFF383838);     // Bordes refinados de 1px
  static const Color borderHighlight = Color(0xFF4A4A4A);// Bordes con foco / hover

  // --- Capas de Superficie Clara (Clean Green-on-White) ---
  static const Color lightBackground = Color(0xFFF9FAFB); // Fondo base limpio
  static const Color lightSurface = Color(0xFFFFFFFF);    // Blanco puro para tarjetas
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF3F4F6); // Contenedor sutil
  static const Color lightBorder = Color(0xFFE5E7EB);     // Borde suave
  static const Color lightBorderHighlight = Color(0xFF059669); // Borde verde de foco

  // --- Tipografía y Estados ---
  static const Color textPrimary = Color(0xFFF8FAFC);    // Blanco perla suave (oscuro)
  static const Color textSecondary = Color(0xFF94A3B8);  // Gris pizarra legible
  static const Color textMuted = Color(0xFF64748B);      // Texto terciario
  static const Color lightTextPrimary = Color(0xFF111827); // Negro carbón de máxima legibilidad
  static const Color lightTextSecondary = Color(0xFF374151); // Gris oscuro legible (>7:1)
  static const Color lightTextMuted = Color(0xFF6B7280);  // Texto atenuado (>4.5:1)
  static const Color errorRed = Color(0xFFF43F5E);       // Carmesí moderno
  static const Color warningOrange = Color(0xFFF59E0B);  // Ámbar cálido

  // --- Helpers Semánticos Adaptativos (Modo Claro / Oscuro) ---
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryColor(BuildContext context) =>
      isDark(context) ? neonGreen : emeraldDark;

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

  /// Estilo estandarizado M3 Expressive para botones de acción en el Header (`AppBar`)
  static ButtonStyle headerActionButtonStyle(
    BuildContext context, {
    bool isFilled = true,
    Color? accentColor,
  }) {
    final dark = isDark(context);
    final primary = accentColor ?? (dark ? neonGreen : emeraldDark);
    final onPrimary = accentColor != null
        ? Colors.white
        : (dark ? const Color(0xFF121212) : Colors.white);
    final disabledBg = (dark ? surfaceElevated : lightSurfaceElevated).withValues(alpha: 0.6);
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
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return onPrimary.withValues(alpha: 0.12);
          }
          return null;
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

  /// Estilo M3 Expressive para botones de ícono en el Header (`AppBar`) sin contenedor
  static ButtonStyle headerIconButtonStyle(
    BuildContext context, {
    Color? foregroundColor,
  }) {
    final dark = isDark(context);
    final fg = foregroundColor ?? (dark ? neonGreen : emeraldDark);

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
          side: isFocused
              ? BorderSide(color: fg, width: 2.0)
              : BorderSide.none,
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
        primary: neonGreen,
        onPrimary: Color(0xFF121212),
        primaryContainer: Color(0xFF063B23),
        onPrimaryContainer: emeraldLight,
        secondary: cyanAccent,
        onSecondary: Color(0xFF121212),
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
        iconTheme: const IconThemeData(color: neonGreen, size: 22),
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
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
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
          borderSide: const BorderSide(color: neonGreen, width: 2),
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
          primary: neonGreen,
          onPrimary: const Color(0xFF121212),
          disabledBg: surfaceElevated,
          disabledFg: textMuted,
          focusBorderColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buildPrimaryButtonStyle(
          primary: neonGreen,
          onPrimary: const Color(0xFF121212),
          disabledBg: surfaceElevated,
          disabledFg: textMuted,
          focusBorderColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buildOutlinedButtonStyle(
          primary: neonGreen,
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
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: neonGreen.withValues(alpha: 0.18),
        side: const BorderSide(color: darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? neonGreen.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? neonGreen
                : textSecondary,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonGreen,
        foregroundColor: Color(0xFF121212),
        shape: StadiumBorder(),
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: emeraldDark,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD1FAE5),
        onPrimaryContainer: Color(0xFF065F46),
        secondary: cyanAccent,
        onSecondary: Color(0xFF121212),
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
        iconTheme: const IconThemeData(color: emeraldDark, size: 22),
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
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
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
          borderSide: const BorderSide(color: emeraldDark, width: 2),
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
          primary: emeraldDark,
          onPrimary: Colors.white,
          disabledBg: lightSurfaceElevated,
          disabledFg: lightTextMuted,
          focusBorderColor: lightTextPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buildPrimaryButtonStyle(
          primary: emeraldDark,
          onPrimary: Colors.white,
          disabledBg: lightSurfaceElevated,
          disabledFg: lightTextMuted,
          focusBorderColor: lightTextPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buildOutlinedButtonStyle(
          primary: emeraldDark,
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
      popupMenuTheme: PopupMenuThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceElevated,
        selectedColor: emeraldDark.withValues(alpha: 0.14),
        side: const BorderSide(color: lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: lightTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? emeraldDark.withValues(alpha: 0.14)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? emeraldDark
                : lightTextSecondary,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emeraldDark,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
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
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
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
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
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
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
