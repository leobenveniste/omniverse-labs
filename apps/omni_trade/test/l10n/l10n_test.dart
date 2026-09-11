import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_trade/l10n/app_localizations.dart';
import 'package:omni_trade/l10n/strings_en.dart';
import 'package:omni_trade/l10n/strings_es.dart';
import 'package:omni_trade/l10n/strings_fr.dart';
import 'package:omni_trade/l10n/strings_it.dart';
import 'package:omni_trade/l10n/strings_pt.dart';

void main() {
  group('AppLocalizations & Translations Tests', () {
    test('All supported languages have identical key sets', () {
      final esKeys = stringsEs.keys.toSet();
      final enKeys = stringsEn.keys.toSet();
      final ptKeys = stringsPt.keys.toSet();
      final frKeys = stringsFr.keys.toSet();
      final itKeys = stringsIt.keys.toSet();

      expect(enKeys.difference(esKeys), isEmpty, reason: 'Keys in EN but not ES');
      expect(esKeys.difference(enKeys), isEmpty, reason: 'Keys in ES but not EN');

      expect(ptKeys.difference(esKeys), isEmpty, reason: 'Keys in PT but not ES');
      expect(esKeys.difference(ptKeys), isEmpty, reason: 'Keys in ES but not PT');

      expect(frKeys.difference(esKeys), isEmpty, reason: 'Keys in FR but not ES');
      expect(esKeys.difference(frKeys), isEmpty, reason: 'Keys in ES but not FR');

      expect(itKeys.difference(esKeys), isEmpty, reason: 'Keys in IT but not ES');
      expect(esKeys.difference(itKeys), isEmpty, reason: 'Keys in ES but not IT');
    });

    test('Translation string replacement with parameters works across languages', () {
      final locEs = AppLocalizations(const Locale('es'));
      expect(
        locEs.t('freePlanBanner', args: {'count': 3, 'max': 15}),
        'Plan Gratis: 3 de 15 operaciones',
      );

      final locEn = AppLocalizations(const Locale('en'));
      expect(
        locEn.t('freePlanBanner', args: {'count': 3, 'max': 15}),
        'Free Plan: 3 of 15 operations used',
      );

      final locPt = AppLocalizations(const Locale('pt'));
      expect(
        locPt.t('freePlanBanner', args: {'count': 3, 'max': 15}),
        'Plano Grátis: 3 de 15 operações usadas',
      );

      final locFr = AppLocalizations(const Locale('fr'));
      expect(
        locFr.t('freePlanBanner', args: {'count': 3, 'max': 15}),
        'Plan Gratuit : 3 sur 15 opérations utilisées',
      );

      final locIt = AppLocalizations(const Locale('it'));
      expect(
        locIt.t('freePlanBanner', args: {'count': 3, 'max': 15}),
        'Piano Gratuito: 3 di 15 operazioni utilizzate',
      );
    });

    test('Language names map properly', () {
      expect(AppLocalizations.getLanguageName('es'), 'Español');
      expect(AppLocalizations.getLanguageName('en'), 'English');
      expect(AppLocalizations.getLanguageName('pt'), 'Português');
      expect(AppLocalizations.getLanguageName('fr'), 'Français');
      expect(AppLocalizations.getLanguageName('it'), 'Italiano');
    });
  });
}
