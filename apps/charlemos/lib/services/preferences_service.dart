import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme_preset.dart';

class PreferencesService extends ChangeNotifier {
  static const String _keyThemePreset = 'charlemos_pref_theme_preset';
  static const String _keyThemeMode = 'charlemos_pref_theme_mode';
  static const String _keyLanguage = 'charlemos_pref_language';
  static const String _keyDevMode = 'charlemos_pref_dev_mode_unlocked';

  final SharedPreferences _prefs;

  AppThemePreset _themePreset = AppThemePreset.coralMist;
  ThemeMode _themeMode = ThemeMode.system;
  String? _languageCode;
  bool _devMode = false;

  PreferencesService(this._prefs) {
    _load();
  }

  AppThemePreset get themePreset => _themePreset;
  ThemeMode get themeMode => _themeMode;
  String? get languageCode => _languageCode;
  bool get isAutoLanguage => _languageCode == null || _languageCode == 'auto';
  Locale? get locale => isAutoLanguage ? null : Locale(_languageCode!);
  static const String _keyHasSeenGuide = 'charlemos_has_seen_guide';
  bool _hasSeenGuide = false;

  bool get hasSeenGuide => _hasSeenGuide;

  Future<void> setHasSeenGuide(bool value) async {
    _hasSeenGuide = value;
    await _prefs.setBool(_keyHasSeenGuide, value);
    notifyListeners();
  }

  void _load() {
    final presetKey = _prefs.getString(_keyThemePreset);
    _themePreset = AppThemePreset.fromKey(presetKey ?? 'neo_kinetic');

    final modeIndex = _prefs.getInt(_keyThemeMode);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    } else {
      _themeMode = ThemeMode.system;
    }

    _languageCode = _prefs.getString(_keyLanguage);
    _devMode = _prefs.getBool(_keyDevMode) ?? false;
    _hasSeenGuide = _prefs.getBool(_keyHasSeenGuide) ?? false;
  }

  Future<void> setThemePreset(AppThemePreset preset) async {
    _themePreset = preset;
    await _prefs.setString(_keyThemePreset, preset.key);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setLanguage(String? code) async {
    _languageCode = (code == null || code == 'auto') ? null : code;
    if (_languageCode == null) {
      await _prefs.remove(_keyLanguage);
    } else {
      await _prefs.setString(_keyLanguage, _languageCode!);
    }
    notifyListeners();
  }

  Future<void> toggleDevMode() async {
    _devMode = !_devMode;
    await _prefs.setBool(_keyDevMode, _devMode);
    notifyListeners();
  }
}
