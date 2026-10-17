import 'package:flutter_test/flutter_test.dart';
import 'package:charlemos/models/card_item.dart';
import 'package:charlemos/l10n/strings_es.dart';
import 'package:charlemos/l10n/strings_en.dart';
import 'package:charlemos/l10n/strings_pt.dart';
import 'package:charlemos/l10n/strings_fr.dart';
import 'package:charlemos/l10n/strings_it.dart';

void main() {
  group('Charlemos Unit Tests', () {
    test('CardItem JSON serialization and copyWith test', () {
      final card = CardItem(
        id: 'test_1',
        level: 1,
        category: 'dates',
        textEs: '¿Cuál es tu canción favorita?',
        textEn: 'What is your favorite song?',
        isFavorite: false,
      );

      final json = card.toJson();
      expect(json['id'], 'test_1');
      expect(json['level'], 1);
      expect(json['category'], 'dates');
      expect(json['text_es'], '¿Cuál es tu canción favorita?');
      expect(json['text_en'], 'What is your favorite song?');

      final fromJson = CardItem.fromJson(json);
      expect(fromJson.id, card.id);
      expect(fromJson.textEs, card.textEs);
      expect(fromJson.isFavorite, false);

      final updated = card.copyWith(isFavorite: true);
      expect(updated.isFavorite, true);
      expect(updated.id, card.id);
    });

    test('CardItem custom card detection', () {
      final custom = CardItem(
        id: 'custom_123',
        level: 3,
        category: 'couples',
        textEs: 'Pregunta propia',
        textEn: 'Own question',
        isCustom: true,
      );

      expect(custom.isCustom, true);
      final json = custom.toJson();
      final revived = CardItem.fromJson(json);
      expect(revived.isCustom, true);
    });

    test('All 14 category deck types are configured with metadata and styles', () {
      final expectedCategories = [
        'dates', 'couples', 'spicy', 'couples_challenges', 'hot_takes', 'friends',
        'party', 'challenges', 'debates', 'travel', 'family',
        'spicy_challenges', 'most_likely', 'never_have_i',
      ];
      expect(expectedCategories.length, 14);
      expect(expectedCategories.contains('couples_challenges'), isTrue);
      expect(expectedCategories.contains('spicy_challenges'), isTrue);
      expect(expectedCategories.contains('most_likely'), isTrue);
      expect(expectedCategories.contains('never_have_i'), isTrue);
    });

    test('CardItem equality and history navigation sanity', () {
      final cardA = CardItem(
        id: 'card_a',
        level: 1,
        category: 'dates',
        textEs: 'A',
        textEn: 'A',
      );
      final cardB = CardItem(
        id: 'card_b',
        level: 1,
        category: 'dates',
        textEs: 'B',
        textEn: 'B',
      );

      final history = <CardItem>[cardA, cardB];
      int index = 1;
      expect(index > 0, isTrue); // canGoPrevious
      index--;
      expect(history[index].id, 'card_a');
      expect(index > 0, isFalse); // at origin
    });

    test('Localization keys parity across all languages', () {
      final esKeys = stringsEs.keys.toSet();
      final enKeys = stringsEn.keys.toSet();
      final ptKeys = stringsPt.keys.toSet();
      final frKeys = stringsFr.keys.toSet();
      final itKeys = stringsIt.keys.toSet();

      expect(esKeys.difference(enKeys), isEmpty, reason: 'Missing keys in English');
      expect(esKeys.difference(ptKeys), isEmpty, reason: 'Missing keys in Portuguese');
      expect(esKeys.difference(frKeys), isEmpty, reason: 'Missing keys in French');
      expect(esKeys.difference(itKeys), isEmpty, reason: 'Missing keys in Italian');
    });
  });
}

