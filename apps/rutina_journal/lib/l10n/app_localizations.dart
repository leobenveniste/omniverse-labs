import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'strings_es.dart';
import 'strings_en.dart';
import 'strings_pt.dart';
import 'strings_fr.dart';
import 'strings_it.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('pt'),
    Locale('fr'),
    Locale('it'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('es'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> get _currentStrings {
    switch (locale.languageCode) {
      case 'en':
        return stringsEn;
      case 'pt':
        return stringsPt;
      case 'fr':
        return stringsFr;
      case 'it':
        return stringsIt;
      case 'es':
      default:
        return stringsEs;
    }
  }

  String t(String key, {Map<String, dynamic>? args}) {
    String value = _currentStrings[key] ?? stringsEn[key] ?? key;
    if (args != null && args.isNotEmpty) {
      args.forEach((k, v) {
        value = value.replaceAll('{$k}', v.toString());
      });
    }
    return value;
  }

  static String getLanguageName(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      default:
        return code.toUpperCase();
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en', 'pt', 'fr', 'it'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
