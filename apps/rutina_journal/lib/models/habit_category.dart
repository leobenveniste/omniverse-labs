import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum HabitCategory {
  health,
  mind,
  productivity,
  sleep,
  personal,
  finance;

  String get key => name;

  String get localizationKey {
    switch (this) {
      case HabitCategory.health:
        return 'catHealth';
      case HabitCategory.mind:
        return 'catMind';
      case HabitCategory.productivity:
        return 'catProductivity';
      case HabitCategory.sleep:
        return 'catSleep';
      case HabitCategory.personal:
        return 'catPersonal';
      case HabitCategory.finance:
        return 'catFinance';
    }
  }

  Color get color {
    switch (this) {
      case HabitCategory.health:
        return AppColors.catHealth;
      case HabitCategory.mind:
        return AppColors.catMind;
      case HabitCategory.productivity:
        return AppColors.catProductivity;
      case HabitCategory.sleep:
        return AppColors.catSleep;
      case HabitCategory.personal:
        return AppColors.catPersonal;
      case HabitCategory.finance:
        return AppColors.catFinance;
    }
  }

  IconData get icon {
    switch (this) {
      case HabitCategory.health:
        return Icons.favorite_rounded;
      case HabitCategory.mind:
        return Icons.self_improvement_rounded;
      case HabitCategory.productivity:
        return Icons.bolt_rounded;
      case HabitCategory.sleep:
        return Icons.bedtime_rounded;
      case HabitCategory.personal:
        return Icons.auto_stories_rounded;
      case HabitCategory.finance:
        return Icons.account_balance_wallet_rounded;
    }
  }

  static HabitCategory fromString(String? val) {
    return HabitCategory.values.firstWhere(
      (c) => c.name == val,
      orElse: () => HabitCategory.health,
    );
  }
}
