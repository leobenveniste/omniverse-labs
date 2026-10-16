/// App constants, product IDs, limits, and supported asset classes for OmniTrade.
class AppConstants {
  AppConstants._();

  static const String appName = 'OmniTrade';
  static const String appVersion = '1.0.2';

  // Freemium tier limitations
  static const int maxFreeTrades = 15;
  static const String proProductId = 'omnitrade_pro_lifetime';

  // Default Base Currencies
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'ARS', 'BRL', 'JPY', 'USDT'];
  static const String defaultCurrency = 'USD';

  // Storage keys
  static const String keyPinCode = 'omnitrade_pin_code';
  static const String keyBiometricsEnabled = 'omnitrade_biometrics_enabled';
  static const String keyAutoLockTimeout = 'omnitrade_autolock_timeout_seconds';
  static const String keyThemeMode = 'omnitrade_theme_mode';
  static const String keyBaseCurrency = 'omnitrade_base_currency';
  static const String keyAccountBalance = 'omnitrade_account_balance';
  static const String keyLocale = 'omnitrade_locale_code';
  static const String keyProOverride = 'omnitrade_test_pro_override';
  static const String keyProPurchased = 'omnitrade_pro_purchased';

  // Default Asset Classes
  static const List<String> assetClasses = [
    'Crypto',
    'Stocks',
    'Forex',
    'Futures',
    'Options',
    'Commodities',
  ];

  // Default Strategy Setups
  static const List<String> defaultStrategies = [
    'Breakout',
    'Pullback / Retest',
    'Trend Following',
    'Range / Mean Reversion',
    'Scalp',
    'Support & Resistance',
    'Order Block / Liquidity',
    'News Catalyst',
  ];

  // Psychological / Mindset Tags
  static const List<String> defaultEmotions = [
    'Disciplined',
    'Followed Plan',
    'Patience',
    'FOMO',
    'Revenge Trade',
    'Greedy / Late Exit',
    'Early Exit (Fear)',
    'Over-leveraged',
  ];
}
