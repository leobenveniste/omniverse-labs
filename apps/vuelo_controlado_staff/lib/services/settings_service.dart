import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyLocale = 'app_locale';
  static const String _keyAutoLocale = 'app_auto_locale';

  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAutoLocale = true;
  Locale _locale = const Locale('es');

  SettingsService(this._prefs) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isAutoTheme => _themeMode == ThemeMode.system;

  bool get isAutoLocale => _isAutoLocale;
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
      _themeMode = ThemeMode.system; // Default al tema del sistema
    }

    _isAutoLocale = _prefs.getBool(_keyAutoLocale) ?? true;
    if (_isAutoLocale) {
      _resolveSystemLocale();
    } else {
      final savedLocale = _prefs.getString(_keyLocale);
      _locale = savedLocale == 'en' ? const Locale('en') : const Locale('es');
    }
    notifyListeners();
  }

  void _resolveSystemLocale() {
    final deviceLocale = PlatformDispatcher.instance.locale;
    if (deviceLocale.languageCode.toLowerCase() == 'en') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('es');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await _prefs.setString(_keyThemeMode, modeStr);
    notifyListeners();
  }

  Future<void> setAutoLocale() async {
    _isAutoLocale = true;
    await _prefs.setBool(_keyAutoLocale, true);
    _resolveSystemLocale();
    notifyListeners();
  }

  Future<void> setLocale(Locale loc) async {
    _isAutoLocale = false;
    _locale = loc;
    await _prefs.setBool(_keyAutoLocale, false);
    await _prefs.setString(_keyLocale, loc.languageCode);
    notifyListeners();
  }
}
