import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../models/guarded_item.dart';

/// Snapshot of all persisted offline CancelGuard preferences and items.
class VaultSnapshot {
  const VaultSnapshot({
    required this.items,
    required this.totalSaved,
    required this.currency,
    required this.locale,
    required this.themeMode,
  });

  final List<GuardedItem> items;
  final double totalSaved;
  final String currency;
  final AppLocale locale;
  final ThemeMode themeMode;
}

/// Offline-only persistence backed by [SharedPreferences].
class VaultStorage {
  VaultStorage(this._prefs);

  static const String _itemsKey = 'cancel_guard.items.v1';
  static const String _totalSavedKey = 'cancel_guard.total_saved.v1';
  static const String _currencyKey = 'cancel_guard.currency.v1';
  static const String _localeKey = 'cancel_guard.locale.v1';
  static const String _themeModeKey = 'cancel_guard.theme_mode.v1';

  final SharedPreferences _prefs;

  /// Creates an initialized [VaultStorage] instance.
  static Future<VaultStorage> open() async {
    final prefs = await SharedPreferences.getInstance();
    return VaultStorage(prefs);
  }

  /// Loads persisted items, ROI savings, currency, language, and theme mode.
  VaultSnapshot load() {
    final rawList = _prefs.getString(_itemsKey);
    final items = <GuardedItem>[];
    if (rawList != null && rawList.isNotEmpty) {
      final decoded = jsonDecode(rawList) as List<dynamic>;
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          items.add(GuardedItem.fromMap(entry));
        }
      }
    }

    final totalSaved = _prefs.getDouble(_totalSavedKey) ?? 0.0;
    final currency = _prefs.getString(_currencyKey) ?? r'$';
    final locale = AppLocale.fromName(_prefs.getString(_localeKey));
    final themeName = _prefs.getString(_themeModeKey);
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => ThemeMode.dark,
    );

    return VaultSnapshot(
      items: items,
      totalSaved: totalSaved,
      currency: currency,
      locale: locale,
      themeMode: themeMode,
    );
  }

  /// Persists the full list of guarded items.
  Future<void> saveItems(List<GuardedItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toMap()).toList());
    await _prefs.setString(_itemsKey, encoded);
  }

  /// Persists lifetime banked savings.
  Future<void> saveTotalSaved(double totalSaved) async {
    await _prefs.setDouble(_totalSavedKey, totalSaved);
  }

  /// Persists selected currency symbol.
  Future<void> saveCurrency(String currency) async {
    await _prefs.setString(_currencyKey, currency);
  }

  /// Persists selected UI language.
  Future<void> saveLocale(AppLocale locale) async {
    await _prefs.setString(_localeKey, locale.name);
  }

  /// Persists selected light/dark/system theme mode.
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _prefs.setString(_themeModeKey, themeMode.name);
  }
}
