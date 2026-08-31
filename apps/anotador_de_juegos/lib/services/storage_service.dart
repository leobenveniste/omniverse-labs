import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session.dart';

class StorageService {
  static const String _keyActiveSession = 'active_game_session';
  static const String _keyHistory = 'game_history';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyKeepScreenAwake = 'keep_screen_awake';

  static Future<void> saveActiveSession(GameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(session.toJson());
    await prefs.setString(_keyActiveSession, jsonString);
  }

  static Future<GameSession?> loadActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyActiveSession);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return GameSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveSession);
  }

  static Future<void> saveToHistory(GameSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    // Prepend new session
    history.insert(0, session);
    // Keep max 50 sessions
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    final listJson = history.map((s) => s.toJson()).toList();
    await prefs.setString(_keyHistory, jsonEncode(listJson));
  }

  static Future<List<GameSession>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyHistory);
    if (jsonString == null) return [];
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((e) => GameSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteHistoryItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    history.removeWhere((s) => s.id == id);
    final listJson = history.map((s) => s.toJson()).toList();
    await prefs.setString(_keyHistory, jsonEncode(listJson));
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }

  static Future<bool> getKeepScreenAwake() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyKeepScreenAwake) ?? true;
  }

  static Future<void> setKeepScreenAwake(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepScreenAwake, value);
  }
}
