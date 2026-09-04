import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme_preset.dart';

class PreferencesService extends ChangeNotifier {
  static const String _keyThemePreset = 'pref_theme_preset';
  static const String _keyThemeMode = 'pref_theme_mode';
  static const String _keyLanguage = 'pref_language';
  static const String _keyNotifHabits = 'pref_notif_habits';
  static const String _keyNotifStreak = 'pref_notif_streak';
  static const String _keyNotifEvening = 'pref_notif_evening';

  final SharedPreferences _prefs;

  AppThemePreset _themePreset = AppThemePreset.calmSage;
  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'es';
  bool _notifHabits = true;
  bool _notifStreak = true;
  bool _notifEvening = true;

  PreferencesService(this._prefs) {
    _load();
  }

  AppThemePreset get themePreset => _themePreset;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);
  bool get notifHabits => _notifHabits;
  bool get notifStreak => _notifStreak;
  bool get notifEvening => _notifEvening;

  void _load() {
    final presetKey = _prefs.getString(_keyThemePreset);
    _themePreset = AppThemePreset.fromKey(presetKey);

    final modeIndex = _prefs.getInt(_keyThemeMode);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    _languageCode = _prefs.getString(_keyLanguage) ?? 'es';
    _notifHabits = _prefs.getBool(_keyNotifHabits) ?? true;
    _notifStreak = _prefs.getBool(_keyNotifStreak) ?? true;
    _notifEvening = _prefs.getBool(_keyNotifEvening) ?? true;
  }

  Future<void> setThemePreset(AppThemePreset preset) async {
    if (_themePreset == preset) return;
    _themePreset = preset;
    await _prefs.setString(_keyThemePreset, preset.key);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    await _prefs.setString(_keyLanguage, code);
    notifyListeners();
  }

  Future<void> setNotifHabits(bool value) async {
    _notifHabits = value;
    await _prefs.setBool(_keyNotifHabits, value);
    notifyListeners();
  }

  Future<void> setNotifStreak(bool value) async {
    _notifStreak = value;
    await _prefs.setBool(_keyNotifStreak, value);
    notifyListeners();
  }

  Future<void> setNotifEvening(bool value) async {
    _notifEvening = value;
    await _prefs.setBool(_keyNotifEvening, value);
    notifyListeners();
  }
}
