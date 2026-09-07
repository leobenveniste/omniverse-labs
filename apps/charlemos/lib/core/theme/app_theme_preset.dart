/// Defines the 3 aesthetic presets available in Charlemos:
/// - coralMist: Default (#FF2E3A & #DBF6FF)
/// - plumOrchid: Tema 1 (#2E0F35 & #FF7FEC)
/// - sunsetSlate: Tema 2 (#FF9030 & #111827)
enum AppThemePreset {
  coralMist,
  plumOrchid,
  sunsetSlate;

  String get key {
    switch (this) {
      case AppThemePreset.coralMist:
        return 'coral_mist';
      case AppThemePreset.plumOrchid:
        return 'plum_orchid';
      case AppThemePreset.sunsetSlate:
        return 'sunset_slate';
    }
  }

  static AppThemePreset fromKey(String? key) {
    switch (key) {
      case 'plum_orchid':
        return AppThemePreset.plumOrchid;
      case 'sunset_slate':
        return AppThemePreset.sunsetSlate;
      case 'coral_mist':
      default:
        return AppThemePreset.coralMist;
    }
  }
}
