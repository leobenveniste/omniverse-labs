import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'card_service.dart';
import 'preferences_service.dart';
import 'premium_service.dart';

class AppServices {
  final SharedPreferences sharedPreferences;
  final PreferencesService preferencesService;
  final PremiumService premiumService;
  final CardService cardService;

  AppServices._({
    required this.sharedPreferences,
    required this.preferencesService,
    required this.premiumService,
    required this.cardService,
  });

  static AppServices of(BuildContext context) {
    return AppServicesScope.of(context);
  }

  static Future<AppServices> init() async {
    final prefs = await SharedPreferences.getInstance();
    final preferences = PreferencesService(prefs);
    final premium = PremiumService(prefs);
    await premium.init();
    final cardService = CardService(prefs);
    await cardService.load();

    return AppServices._(
      sharedPreferences: prefs,
      preferencesService: preferences,
      premiumService: premium,
      cardService: cardService,
    );
  }
}

class AppServicesScope extends InheritedWidget {
  final AppServices services;

  const AppServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  static AppServices of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'No AppServicesScope found in context');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) => false;
}
