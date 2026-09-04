import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/routine.dart';
import '../models/journal_entry.dart';

class StorageService {
  static const String _keyHabits = 'storage_habits';
  static const String _keyLogs = 'storage_habit_logs';
  static const String _keyRoutines = 'storage_routines';
  static const String _keyJournal = 'storage_journal_entries';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // --- HABITS ---
  Future<List<Habit>> loadHabits() async {
    final raw = _prefs.getString(_keyHabits);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final raw = jsonEncode(habits.map((h) => h.toJson()).toList());
    await _prefs.setString(_keyHabits, raw);
  }

  // --- HABIT LOGS ---
  Future<List<HabitLog>> loadHabitLogs() async {
    final raw = _prefs.getString(_keyLogs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => HabitLog.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHabitLogs(List<HabitLog> logs) async {
    final raw = jsonEncode(logs.map((l) => l.toJson()).toList());
    await _prefs.setString(_keyLogs, raw);
  }

  // --- ROUTINES ---
  Future<List<Routine>> loadRoutines() async {
    final raw = _prefs.getString(_keyRoutines);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Routine.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRoutines(List<Routine> routines) async {
    final raw = jsonEncode(routines.map((r) => r.toJson()).toList());
    await _prefs.setString(_keyRoutines, raw);
  }

  // --- JOURNAL ENTRIES ---
  Future<List<JournalEntry>> loadJournalEntries() async {
    final raw = _prefs.getString(_keyJournal);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveJournalEntries(List<JournalEntry> entries) async {
    final raw = jsonEncode(entries.map((j) => j.toJson()).toList());
    await _prefs.setString(_keyJournal, raw);
  }

  // --- FULL EXPORT & IMPORT ---
  Future<String> exportFullJson() async {
    final habits = await loadHabits();
    final logs = await loadHabitLogs();
    final routines = await loadRoutines();
    final journal = await loadJournalEntries();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habits.map((h) => h.toJson()).toList(),
      'logs': logs.map((l) => l.toJson()).toList(),
      'routines': routines.map((r) => r.toJson()).toList(),
      'journal': journal.map((j) => j.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importFullJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      if (data.containsKey('habits')) {
        final habits = (data['habits'] as List<dynamic>)
            .map((e) => Habit.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveHabits(habits);
      }
      if (data.containsKey('logs')) {
        final logs = (data['logs'] as List<dynamic>)
            .map((e) => HabitLog.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveHabitLogs(logs);
      }
      if (data.containsKey('routines')) {
        final routines = (data['routines'] as List<dynamic>)
            .map((e) => Routine.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveRoutines(routines);
      }
      if (data.containsKey('journal')) {
        final journal = (data['journal'] as List<dynamic>)
            .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveJournalEntries(journal);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
