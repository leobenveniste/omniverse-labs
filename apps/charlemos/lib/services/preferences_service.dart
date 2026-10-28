import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme_preset.dart';

class PreferencesService extends ChangeNotifier {
  static const String _keyThemePreset = 'charlemos_pref_theme_preset';
  static const String _keyThemeMode = 'charlemos_pref_theme_mode';
  static const String _keyLanguage = 'charlemos_pref_language';
  static const String _keyDevMode = 'charlemos_pref_dev_mode_unlocked';

  static const String _keyCardsDrawnCount = 'charlemos_cards_drawn_count';
  static const String _keyHasRatedApp = 'charlemos_has_rated_app';
  static const String _keyNextRatingPromptCount = 'charlemos_next_rating_prompt_count';

  final SharedPreferences _prefs;

  AppThemePreset _themePreset = AppThemePreset.coralMist;
  ThemeMode _themeMode = ThemeMode.system;
  String? _languageCode;
  bool _devMode = false;
  static const String _keyHasSeenGuide = 'charlemos_has_seen_guide';
  bool _hasSeenGuide = false;
  int _cardsDrawnCount = 0;
  bool _hasRatedApp = false;
  int _nextRatingPromptCount = 15;

  PreferencesService(this._prefs) {
    _load();
  }

  AppThemePreset get themePreset => _themePreset;
  ThemeMode get themeMode => _themeMode;
  String? get languageCode => _languageCode;
  bool get isAutoLanguage => _languageCode == null || _languageCode == 'auto';
  Locale? get locale => isAutoLanguage ? null : Locale(_languageCode!);
  bool get isDevMode => _devMode;
  bool get hasSeenGuide => _hasSeenGuide;
  int get cardsDrawnCount => _cardsDrawnCount;
  bool get hasRatedApp => _hasRatedApp;
  bool get shouldShowRatingPrompt => !_hasRatedApp && _cardsDrawnCount >= _nextRatingPromptCount;

  Future<void> setHasSeenGuide(bool value) async {
    _hasSeenGuide = value;
    await _prefs.setBool(_keyHasSeenGuide, value);
    notifyListeners();
  }

  Future<void> incrementCardsDrawn() async {
    _cardsDrawnCount++;
    await _prefs.setInt(_keyCardsDrawnCount, _cardsDrawnCount);
  }

  Future<void> markRatedApp() async {
    _hasRatedApp = true;
    await _prefs.setBool(_keyHasRatedApp, true);
    notifyListeners();
  }

  Future<void> postponeRatingPrompt() async {
    _nextRatingPromptCount = _cardsDrawnCount + 30;
    await _prefs.setInt(_keyNextRatingPromptCount, _nextRatingPromptCount);
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
    _cardsDrawnCount = _prefs.getInt(_keyCardsDrawnCount) ?? 0;
    _hasRatedApp = _prefs.getBool(_keyHasRatedApp) ?? false;
    _nextRatingPromptCount = _prefs.getInt(_keyNextRatingPromptCount) ?? 15;
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
