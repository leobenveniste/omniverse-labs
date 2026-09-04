import 'package:flutter_test/flutter_test.dart';
import 'package:rutina_journal/l10n/strings_es.dart';
import 'package:rutina_journal/l10n/strings_en.dart';
import 'package:rutina_journal/l10n/strings_pt.dart';
import 'package:rutina_journal/l10n/strings_fr.dart';
import 'package:rutina_journal/l10n/strings_it.dart';

void main() {
  group('5-Language Localization Key Parity Tests', () {
    test('All language maps have matching keys with Spanish base', () {
      final baseKeys = stringsEs.keys.toSet();

      final enKeys = stringsEn.keys.toSet();
      final ptKeys = stringsPt.keys.toSet();
      final frKeys = stringsFr.keys.toSet();
      final itKeys = stringsIt.keys.toSet();

      expect(enKeys.difference(baseKeys), isEmpty, reason: 'English has extra keys');
      expect(baseKeys.difference(enKeys), isEmpty, reason: 'English is missing keys');

      expect(ptKeys.difference(baseKeys), isEmpty, reason: 'Portuguese has extra keys');
      expect(baseKeys.difference(ptKeys), isEmpty, reason: 'Portuguese is missing keys');

      expect(frKeys.difference(baseKeys), isEmpty, reason: 'French has extra keys');
      expect(baseKeys.difference(frKeys), isEmpty, reason: 'French is missing keys');

      expect(itKeys.difference(baseKeys), isEmpty, reason: 'Italian has extra keys');
      expect(baseKeys.difference(itKeys), isEmpty, reason: 'Italian is missing keys');
    });

    test('No language has empty translated strings', () {
      final allMaps = [stringsEs, stringsEn, stringsPt, stringsFr, stringsIt];
      for (final map in allMaps) {
        for (final entry in map.entries) {
          expect(entry.value.trim().isNotEmpty, isTrue,
              reason: 'Key "${entry.key}" has empty value');
        }
      }
    });
  });
}
