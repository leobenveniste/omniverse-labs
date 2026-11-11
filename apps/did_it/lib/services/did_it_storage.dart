import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/did_it_models.dart';

/// Persisted snapshot of all items, flows, confirmation logbook, and user settings.
class DidItSnapshot {
  const DidItSnapshot({
    required this.items,
    required this.flows,
    required this.history,
    required this.themeMode,
    required this.localeCode,
    required this.defaultSnoozeMinutes,
    required this.seededDemo,
  });

  final List<DidItItem> items;
  final List<CheckFlow> flows;
  final List<CompletionEvent> history;
  final ThemeMode themeMode;
  final String localeCode;
  final int defaultSnoozeMinutes;
  final bool seededDemo;
}

/// Offline SharedPreferences storage repository with zero network dependencies.
class DidItStorage {
  DidItStorage(this._prefs);

  static const String _itemsKey = 'did_it_items_v1';
  static const String _flowsKey = 'did_it_flows_v1';
  static const String _historyKey = 'did_it_history_v1';
  static const String _themeKey = 'did_it_theme_v1';
  static const String _localeKey = 'did_it_locale_v1';
  static const String _snoozeKey = 'did_it_snooze_min_v1';
  static const String _seededKey = 'did_it_seeded_v1';
  static const int maxHistoryEntries = 500;

  final SharedPreferences _prefs;

  static Future<DidItStorage> open() async {
    final prefs = await SharedPreferences.getInstance();
    return DidItStorage(prefs);
  }

  DidItSnapshot loadSnapshot() {
    final items = _decodeList<DidItItem>(
      _prefs.getString(_itemsKey),
      DidItItem.fromJson,
    );
    final flows = _decodeList<CheckFlow>(
      _prefs.getString(_flowsKey),
      CheckFlow.fromJson,
    );
    final history = _decodeList<CompletionEvent>(
      _prefs.getString(_historyKey),
      CompletionEvent.fromJson,
    );

    final themeRaw = _prefs.getString(_themeKey);
    final themeMode = themeRaw == 'light' ? ThemeMode.light : ThemeMode.dark;
    final localeCode = _prefs.getString(_localeKey) ?? 'en';
    final defaultSnoozeMinutes = (_prefs.getInt(_snoozeKey) ?? 30).clamp(5, 180);
    final seededDemo = _prefs.getBool(_seededKey) ?? false;

    return DidItSnapshot(
      items: items,
      flows: flows,
      history: history,
      themeMode: themeMode,
      localeCode: localeCode,
      defaultSnoozeMinutes: defaultSnoozeMinutes,
      seededDemo: seededDemo,
    );
  }

  Future<void> saveState({
    required List<DidItItem> items,
    required List<CheckFlow> flows,
    required List<CompletionEvent> history,
  }) async {
    final cappedHistory = history.length > maxHistoryEntries
        ? history.sublist(0, maxHistoryEntries)
        : history;

    await Future.wait(<Future<bool>>[
      _prefs.setString(
        _itemsKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      ),
      _prefs.setString(
        _flowsKey,
        jsonEncode(flows.map((e) => e.toJson()).toList()),
      ),
      _prefs.setString(
        _historyKey,
        jsonEncode(cappedHistory.map((e) => e.toJson()).toList()),
      ),
    ]);
  }

  Future<void> savePreferences({
    required ThemeMode themeMode,
    required String localeCode,
    required int defaultSnoozeMinutes,
  }) async {
    await Future.wait(<Future<bool>>[
      _prefs.setString(
        _themeKey,
        themeMode == ThemeMode.light ? 'light' : 'dark',
      ),
      _prefs.setString(_localeKey, localeCode),
      _prefs.setInt(_snoozeKey, defaultSnoozeMinutes),
    ]);
  }

  Future<void> markSeeded() => _prefs.setBool(_seededKey, true);

  Future<void> reload() => _prefs.reload();

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) builder,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <T>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(builder)
          .toList();
    } catch (_) {
      return <T>[];
    }
  }
}
