import 'package:flutter/material.dart';

enum TableMatStyle {
  arcade,
  casinoGreen,
  mahogany,
  synthwave,
  vintageLeather;

  String get id => name;

  bool get isPro => this != TableMatStyle.arcade;

  String get nameKey {
    switch (this) {
      case TableMatStyle.arcade:
        return 'matArcade';
      case TableMatStyle.casinoGreen:
        return 'matCasinoGreen';
      case TableMatStyle.mahogany:
        return 'matMahogany';
      case TableMatStyle.synthwave:
        return 'matSynthwave';
      case TableMatStyle.vintageLeather:
        return 'matVintageLeather';
    }
  }

  String get descKey {
    switch (this) {
      case TableMatStyle.arcade:
        return 'matArcadeDesc';
      case TableMatStyle.casinoGreen:
        return 'matCasinoGreenDesc';
      case TableMatStyle.mahogany:
        return 'matMahoganyDesc';
      case TableMatStyle.synthwave:
        return 'matSynthwaveDesc';
      case TableMatStyle.vintageLeather:
        return 'matVintageLeatherDesc';
    }
  }

  IconData get icon {
    switch (this) {
      case TableMatStyle.arcade:
        return Icons.grid_view_rounded;
      case TableMatStyle.casinoGreen:
        return Icons.casino_rounded;
      case TableMatStyle.mahogany:
        return Icons.forest_rounded;
      case TableMatStyle.synthwave:
        return Icons.nightlife_rounded;
      case TableMatStyle.vintageLeather:
        return Icons.layers_rounded;
    }
  }

  Color get primaryColor {
    switch (this) {
      case TableMatStyle.arcade:
        return const Color(0xFF6C5CE7);
      case TableMatStyle.casinoGreen:
        return const Color(0xFF10B981);
      case TableMatStyle.mahogany:
        return const Color(0xFFE17055);
      case TableMatStyle.synthwave:
        return const Color(0xFFFD79A8);
      case TableMatStyle.vintageLeather:
        return const Color(0xFFF39C12);
    }
  }

  Color get accentColor {
    switch (this) {
      case TableMatStyle.arcade:
        return const Color(0xFF00CEC9);
      case TableMatStyle.casinoGreen:
        return const Color(0xFFFFD700);
      case TableMatStyle.mahogany:
        return const Color(0xFFFFBE76);
      case TableMatStyle.synthwave:
        return const Color(0xFF00FFFF);
      case TableMatStyle.vintageLeather:
        return const Color(0xFFF1C40F);
    }
  }

  Color get surfaceColor {
    switch (this) {
      case TableMatStyle.arcade:
        return const Color(0xFF161B26);
      case TableMatStyle.casinoGreen:
        return const Color(0xFF0D2818);
      case TableMatStyle.mahogany:
        return const Color(0xFF26140D);
      case TableMatStyle.synthwave:
        return const Color(0xFF1E0E3E);
      case TableMatStyle.vintageLeather:
        return const Color(0xFF2B1D14);
    }
  }

  Color get borderColor {
    switch (this) {
      case TableMatStyle.arcade:
        return const Color(0xFF2D3748);
      case TableMatStyle.casinoGreen:
        return const Color(0xFF1B4332);
      case TableMatStyle.mahogany:
        return const Color(0xFF4A2511);
      case TableMatStyle.synthwave:
        return const Color(0xFF3F1D68);
      case TableMatStyle.vintageLeather:
        return const Color(0xFF4A3525);
    }
  }

  LinearGradient get backgroundGradient {
    switch (this) {
      case TableMatStyle.arcade:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B0F17),
            Color(0xFF06090E),
          ],
        );
      case TableMatStyle.casinoGreen:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A2617),
            Color(0xFF05170D),
          ],
        );
      case TableMatStyle.mahogany:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E0E08),
            Color(0xFF130804),
          ],
        );
      case TableMatStyle.synthwave:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF150728),
            Color(0xFF0A0314),
          ],
        );
      case TableMatStyle.vintageLeather:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1D140D),
            Color(0xFF110B07),
          ],
        );
    }
  }

  static TableMatStyle fromId(String? id) {
    if (id == null) return TableMatStyle.arcade;
    return TableMatStyle.values.firstWhere(
      (e) => e.name == id,
      orElse: () => TableMatStyle.arcade,
    );
  }
}
