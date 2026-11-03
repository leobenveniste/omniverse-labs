import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class SettingsService extends ChangeNotifier {
  final SharedPreferences _prefs;

  final String _themeModeKey = 'circulo_theme_mode';
  final String _localeCodeKey = 'circulo_locale_code';
  final String _welcomeSeenKey = 'circulo_welcome_seen';
  final String _biometricKey = 'circulo_biometric_enabled';

  SettingsService(this._prefs);

  ThemeMode get themeMode {
    final mode = _prefs.getString(_themeModeKey) ?? 'system';
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String get themeModeName => _prefs.getString(_themeModeKey) ?? 'system';

  Future<void> setThemeModePreference(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
    notifyListeners();
  }

  String get localeCode => _prefs.getString(_localeCodeKey) ?? 'auto';

  Locale? get explicitLocale {
    final code = localeCode;
    if (code == 'auto') return null;
    return Locale(code);
  }

  Locale resolveEffectiveLocale(Locale? deviceLocale) {
    return AppLocalizations.resolveLocale(deviceLocale, localeCode);
  }

  Future<void> setLocaleCode(String code) async {
    await _prefs.setString(_localeCodeKey, code);
    notifyListeners();
  }

  bool get welcomeGuideSeen => _prefs.getBool(_welcomeSeenKey) ?? false;

  Future<void> markWelcomeGuideSeen() async {
    await _prefs.setBool(_welcomeSeenKey, true);
    notifyListeners();
  }

  bool get biometricEnabled => _prefs.getBool(_biometricKey) ?? false;

  Future<void> setBiometricEnabled(bool value) async {
    await _prefs.setBool(_biometricKey, value);
    notifyListeners();
  }
}
