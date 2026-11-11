import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/pulse_models.dart';

/// Local offline persistence for PulsePocket preferences and 1-Tap Setlist Slots.
class PulseStorage {
  PulseStorage._(this._prefs);

  final SharedPreferences _prefs;

  static const _bpmKey = 'pp_bpm_v1';
  static const _signatureKey = 'pp_signature_v1';
  static const _slotsKey = 'pp_slots_v1';
  static const _localeKey = 'pp_locale_v1';
  static const _themeKey = 'pp_theme_v1';
  static const _hapticStrengthKey = 'pp_haptic_strength_v1';
  static const _visualFlashKey = 'pp_visual_flash_v1';
  static const _keepAwakeKey = 'pp_keep_awake_v1';

  static Future<PulseStorage> open() async {
    final prefs = await SharedPreferences.getInstance();
    return PulseStorage._(prefs);
  }

  int loadBpm() => (_prefs.getInt(_bpmKey) ?? kDefaultBpm).clamp(kMinBpm, kMaxBpm);

  Future<void> saveBpm(int bpm) async {
    await _prefs.setInt(_bpmKey, bpm.clamp(kMinBpm, kMaxBpm));
  }

  TimeSignatureOption loadSignature() =>
      TimeSignatureOption.fromName(_prefs.getString(_signatureKey));

  Future<void> saveSignature(TimeSignatureOption sig) async {
    await _prefs.setString(_signatureKey, sig.name);
  }

  AppLocale loadLocale() => AppLocale.fromName(_prefs.getString(_localeKey));

  Future<void> saveLocale(AppLocale locale) async {
    await _prefs.setString(_localeKey, locale.name);
  }

  ThemeMode loadThemeMode() {
    final raw = _prefs.getString(_themeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemeMode.dark,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
  }

  HapticStrength loadHapticStrength() =>
      HapticStrength.fromName(_prefs.getString(_hapticStrengthKey));

  Future<void> saveHapticStrength(HapticStrength strength) async {
    await _prefs.setString(_hapticStrengthKey, strength.name);
  }

  bool loadVisualFlash() => _prefs.getBool(_visualFlashKey) ?? true;

  Future<void> saveVisualFlash(bool enabled) async {
    await _prefs.setBool(_visualFlashKey, enabled);
  }

  bool loadKeepAwake() => _prefs.getBool(_keepAwakeKey) ?? true;

  Future<void> saveKeepAwake(bool enabled) async {
    await _prefs.setBool(_keepAwakeKey, enabled);
  }

  List<SetlistSlot> loadSlots() {
    final raw = _prefs.getString(_slotsKey);
    if (raw == null) {
      return _defaultStarterSlots();
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SetlistSlot.fromJson)
          .whereType<SetlistSlot>()
          .take(kMaxSetlistSlots)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSlots(List<SetlistSlot> slots) async {
    final encoded = jsonEncode(
      slots.take(kMaxSetlistSlots).map((s) => s.toJson()).toList(),
    );
    await _prefs.setString(_slotsKey, encoded);
  }

  static List<SetlistSlot> _defaultStarterSlots() {
    const uuid = Uuid();
    return [
      SetlistSlot(
        id: uuid.v4(),
        name: 'Warmup',
        bpm: 90,
        signature: TimeSignatureOption.fourFour,
      ),
      SetlistSlot(
        id: uuid.v4(),
        name: 'Stage Groove',
        bpm: 120,
        signature: TimeSignatureOption.fourFour,
      ),
      SetlistSlot(
        id: uuid.v4(),
        name: 'Encore Drive',
        bpm: 138,
        signature: TimeSignatureOption.sixEight,
      ),
    ];
  }
}
