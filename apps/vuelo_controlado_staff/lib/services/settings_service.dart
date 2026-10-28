import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyLocale = 'app_locale';

  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('es');

  SettingsService(this._prefs) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isSpanish => _locale.languageCode == 'es';

  void _loadSettings() {
    final savedTheme = _prefs.getString(_keyThemeMode);
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark; // Default a Dark obsidian
    }

    final savedLocale = _prefs.getString(_keyLocale);
    if (savedLocale == 'en') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('es');
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _prefs.setString(_keyThemeMode, modeStr);
    notifyListeners();
  }

  Future<void> setLocale(Locale loc) async {
    _locale = loc;
    await _prefs.setString(_keyLocale, loc.languageCode);
    notifyListeners();
  }
}
