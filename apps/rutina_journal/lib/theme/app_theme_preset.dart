/// Defines the 3 aesthetic presets available to the user in Settings.
enum AppThemePreset {
  calmSage,
  neoKinetic,
  midnightBento;

  String get key {
    switch (this) {
      case AppThemePreset.calmSage:
        return 'calm_sage';
      case AppThemePreset.neoKinetic:
        return 'neo_kinetic';
      case AppThemePreset.midnightBento:
        return 'midnight_bento';
    }
  }

  static AppThemePreset fromKey(String? key) {
    switch (key) {
      case 'neo_kinetic':
        return AppThemePreset.neoKinetic;
      case 'midnight_bento':
        return AppThemePreset.midnightBento;
      case 'calm_sage':
      default:
        return AppThemePreset.calmSage;
    }
  }
}
