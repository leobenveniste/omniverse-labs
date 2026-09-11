import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/subscription/subscription_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final SubscriptionService _subscriptionService;

  ThemeMode _themeMode = ThemeMode.dark; // Dark financial terminal default
  String _baseCurrency = AppConstants.defaultCurrency;
  double _accountBalance = 10000.0; // Default base capital
  Locale? _locale;

  SettingsProvider(this._prefs, this._subscriptionService) {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  String get baseCurrency => _baseCurrency;
  double get accountBalance => _accountBalance;
  Locale? get locale => _locale;
  bool get isPro => _subscriptionService.isPro;
  bool get isTestProOverride => _subscriptionService.isTestProOverride;

  String get currencySymbol {
    switch (_baseCurrency) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'BRL':
        return 'R\$';
      case 'USDT':
        return '₮';
      case 'USD':
      case 'ARS':
      default:
        return '\$';
    }
  }

  void _loadSettings() {
    final themeIndex = _prefs.getInt(AppConstants.keyThemeMode);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    } else {
      _themeMode = ThemeMode.dark;
    }

    _baseCurrency = _prefs.getString(AppConstants.keyBaseCurrency) ?? AppConstants.defaultCurrency;
    _accountBalance = _prefs.getDouble(AppConstants.keyAccountBalance) ?? 10000.0;
    final localeCode = _prefs.getString(AppConstants.keyLocale);
    if (localeCode != null && localeCode.isNotEmpty) {
      _locale = Locale(localeCode);
    }
    notifyListeners();
  }

  Future<void> setLocale(String? languageCode) async {
    if (languageCode == null || languageCode.isEmpty) {
      _locale = null;
      await _prefs.remove(AppConstants.keyLocale);
    } else {
      _locale = Locale(languageCode);
      await _prefs.setString(AppConstants.keyLocale, languageCode);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(AppConstants.keyThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setBaseCurrency(String currency) async {
    _baseCurrency = currency;
    await _prefs.setString(AppConstants.keyBaseCurrency, currency);
    notifyListeners();
  }

  Future<void> setAccountBalance(double balance) async {
    _accountBalance = balance;
    await _prefs.setDouble(AppConstants.keyAccountBalance, balance);
    notifyListeners();
  }

  Future<void> toggleTestPro(bool enabled) async {
    await _subscriptionService.setTestProOverride(enabled);
    notifyListeners();
  }

  void refreshEntitlement() {
    notifyListeners();
  }
}
