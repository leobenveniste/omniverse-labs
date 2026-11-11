import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/loud_models.dart';

class LoudStorage {
  LoudStorage(this._prefs);

  static const String _keyThemeMode = 'loud_guard_theme_mode';
  static const String _keyLocale = 'loud_guard_locale';
  static const String _keyCalibrationOffset = 'loud_guard_calibration_offset';
  static const String _keyHapticThreshold = 'loud_guard_haptic_threshold';
  static const String _keyKeepAwake = 'loud_guard_keep_awake';
  static const String _keySavedChecks = 'loud_guard_saved_checks';

  final SharedPreferences _prefs;

  static Future<LoudStorage> open() async {
    final prefs = await SharedPreferences.getInstance();
    return LoudStorage(prefs);
  }

  ThemeMode loadThemeMode() {
    final raw = _prefs.getString(_keyThemeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await _prefs.setString(_keyThemeMode, value);
  }

  AppLocale loadLocale() => AppLocale.fromCode(_prefs.getString(_keyLocale));

  Future<void> saveLocale(AppLocale locale) async {
    await _prefs.setString(_keyLocale, locale.code);
  }

  double loadCalibrationOffset() {
    final raw = _prefs.getDouble(_keyCalibrationOffset) ?? 0.0;
    return raw.clamp(kMinCalibrationOffset, kMaxCalibrationOffset);
  }

  Future<void> saveCalibrationOffset(double offsetDb) async {
    await _prefs.setDouble(
      _keyCalibrationOffset,
      offsetDb.clamp(kMinCalibrationOffset, kMaxCalibrationOffset),
    );
  }

  HapticThreshold loadHapticThreshold() {
    return HapticThreshold.fromStorage(_prefs.getString(_keyHapticThreshold));
  }

  Future<void> saveHapticThreshold(HapticThreshold threshold) async {
    await _prefs.setString(_keyHapticThreshold, threshold.name);
  }

  bool loadKeepScreenAwake() => _prefs.getBool(_keyKeepAwake) ?? true;

  Future<void> saveKeepScreenAwake(bool enabled) async {
    await _prefs.setBool(_keyKeepAwake, enabled);
  }

  List<SoundCheckLog> loadSavedChecks() {
    final raw = _prefs.getString(_keySavedChecks);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(SoundCheckLog.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChecks(List<SoundCheckLog> checks) async {
    final encoded = jsonEncode(checks.map((c) => c.toJson()).toList());
    await _prefs.setString(_keySavedChecks, encoded);
  }
}
