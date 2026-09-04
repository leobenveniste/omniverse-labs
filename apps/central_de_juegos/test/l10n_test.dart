import 'package:flutter_test/flutter_test.dart';
import 'package:central_de_juegos/l10n/strings_es.dart';
import 'package:central_de_juegos/l10n/strings_en.dart';
import 'package:central_de_juegos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void main() {
  group('Localization Parity Tests', () {
    test('Spanish and English key count must match exactly', () {
      expect(
        stringsEs.keys.length,
        equals(stringsEn.keys.length),
        reason: 'Number of translation keys in stringsEs and stringsEn should be identical',
      );
    });

    test('All Spanish keys must be present and non-empty in English', () {
      final missingInEn = <String>[];
      final emptyInEn = <String>[];

      for (final key in stringsEs.keys) {
        if (!stringsEn.containsKey(key)) {
          missingInEn.add(key);
        } else if (stringsEn[key]!.trim().isEmpty) {
          emptyInEn.add(key);
        }
      }

      expect(missingInEn, isEmpty, reason: 'Keys missing in English: $missingInEn');
      expect(emptyInEn, isEmpty, reason: 'Empty keys in English: $emptyInEn');
    });

    test('All English keys must be present and non-empty in Spanish', () {
      final missingInEs = <String>[];
      final emptyInEs = <String>[];

      for (final key in stringsEn.keys) {
        if (!stringsEs.containsKey(key)) {
          missingInEs.add(key);
        } else if (stringsEs[key]!.trim().isEmpty) {
          emptyInEs.add(key);
        }
      }

      expect(missingInEs, isEmpty, reason: 'Keys missing in Spanish: $missingInEs');
      expect(emptyInEs, isEmpty, reason: 'Empty keys in Spanish: $emptyInEs');
    });

    test('AppLocalizations delegate loads and interpolates correctly', () {
      final esL10n = AppLocalizations(const Locale('es'));
      expect(esL10n.t('appName'), equals('Central de Juegos'));
      expect(
        esL10n.t('winnerLabel', {'name': 'Leo'}),
        equals('Ganador: Leo'),
      );

      final enL10n = AppLocalizations(const Locale('en'));
      expect(enL10n.t('appName'), equals('Game Night Hub'));
      expect(
        enL10n.t('winnerLabel', {'name': 'Leo'}),
        equals('Winner: Leo'),
      );
    });
  });
}
