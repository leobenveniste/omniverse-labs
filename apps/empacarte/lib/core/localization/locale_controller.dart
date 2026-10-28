import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const String _localePrefKey = 'empacarte_locale_code';

  bool _isAutoDetect = true;
  Locale _currentLocale = const Locale('en');

  bool get isAutoDetect => _isAutoDetect;
  Locale get currentLocale => _currentLocale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localePrefKey);

    if (savedCode == null || savedCode == 'auto') {
      _isAutoDetect = true;
      _currentLocale = _resolveSystemLocale();
    } else {
      _isAutoDetect = false;
      _currentLocale = Locale(savedCode);
    }
    notifyListeners();
  }

  Locale _resolveSystemLocale() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final supportedCodes = ['en', 'es', 'it', 'fr', 'pt', 'de'];
    if (supportedCodes.contains(deviceLocale.languageCode)) {
      return Locale(deviceLocale.languageCode);
    }
    return const Locale('en');
  }

  Future<void> setAutoDetect() async {
    _isAutoDetect = true;
    _currentLocale = _resolveSystemLocale();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, 'auto');
  }

  Future<void> setLocale(String languageCode) async {
    _isAutoDetect = false;
    _currentLocale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, languageCode);
  }
}
