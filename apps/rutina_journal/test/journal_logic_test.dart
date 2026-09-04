import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutina_journal/services/journal_service.dart';
import 'package:rutina_journal/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late JournalService journalService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    journalService = JournalService(storage);
    await journalService.load();
  });

  group('JournalService Logic Tests', () {
    test('Can save and retrieve journal entry with mood and gratitudes', () async {
      final todayKey = '2026-09-03';

      await journalService.saveEntry(
        dateKey: todayKey,
        moodLevel: 5,
        energyLevel: 4,
        tags: ['calm', 'focused'],
        gratitude1: 'Morning coffee',
        gratitude2: 'Sunshine',
        gratitude3: 'Great conversation',
        dailyWin: 'Finished app implementation plan',
        notes: 'Feeling motivated.',
      );

      final entry = journalService.getEntryForDate(DateTime(2026, 9, 3));
      expect(entry.moodLevel, 5);
      expect(entry.energyLevel, 4);
      expect(entry.tags, contains('calm'));
      expect(entry.gratitude1, 'Morning coffee');
      expect(entry.dailyWin, 'Finished app implementation plan');
    });

    test('Computes average mood across entries', () async {
      await journalService.saveEntry(
        dateKey: '2026-09-01',
        moodLevel: 4,
        energyLevel: 3,
        tags: [],
        gratitude1: '',
        gratitude2: '',
        gratitude3: '',
        dailyWin: '',
        notes: '',
      );

      await journalService.saveEntry(
        dateKey: '2026-09-02',
        moodLevel: 2,
        energyLevel: 2,
        tags: [],
        gratitude1: '',
        gratitude2: '',
        gratitude3: '',
        dailyWin: '',
        notes: '',
      );

      expect(journalService.getAverageMood(), 3.0);
    });
  });
}
