import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../utils/date_utils.dart';
import 'storage_service.dart';

class JournalService extends ChangeNotifier {
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  Map<String, JournalEntry> _entries = {};
  bool _isLoading = true;

  JournalService(this._storage) {
    load();
  }

  bool get isLoading => _isLoading;
  List<JournalEntry> get allEntries {
    final list = _entries.values.toList();
    list.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return list;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final list = await _storage.loadJournalEntries();
    _entries = {for (final e in list) e.dateKey: e};

    _isLoading = false;
    notifyListeners();
  }

  JournalEntry getEntryForDate(DateTime date) {
    final key = AppDateUtils.toDateKey(date);
    return _entries[key] ??
        JournalEntry(
          id: _uuid.v4(),
          dateKey: key,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  Future<void> saveEntry({
    required String dateKey,
    required int moodLevel,
    required int energyLevel,
    required List<String> tags,
    required String gratitude1,
    required String gratitude2,
    required String gratitude3,
    required String dailyWin,
    required String notes,
  }) async {
    final existing = _entries[dateKey];
    final updated = JournalEntry(
      id: existing?.id ?? _uuid.v4(),
      dateKey: dateKey,
      moodLevel: moodLevel,
      energyLevel: energyLevel,
      tags: tags,
      gratitude1: gratitude1.trim(),
      gratitude2: gratitude2.trim(),
      gratitude3: gratitude3.trim(),
      dailyWin: dailyWin.trim(),
      notes: notes.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _entries[dateKey] = updated;
    await _storage.saveJournalEntries(_entries.values.toList());
    notifyListeners();
  }

  // Correlation analysis between habit completion and mood
  double getAverageMood() {
    if (_entries.isEmpty) return 4.0;
    final sum = _entries.values.fold<int>(0, (acc, e) => acc + e.moodLevel);
    return sum / _entries.length;
  }
}
