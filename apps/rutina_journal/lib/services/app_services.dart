import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_service.dart';
import 'habit_service.dart';
import 'journal_service.dart';
import 'notification_service.dart';
import 'preferences_service.dart';
import 'premium_service.dart';
import 'routine_service.dart';
import 'storage_service.dart';
import 'widget_sync_service.dart';

class AppServices {
  final SharedPreferences sharedPreferences;
  final StorageService storageService;
  final NotificationService notificationService;
  final PreferencesService preferencesService;
  final PremiumService premiumService;
  final HabitService habitService;
  final RoutineService routineService;
  final JournalService journalService;
  final AudioService audioService;
  final WidgetSyncService widgetSyncService;

  AppServices._({
    required this.sharedPreferences,
    required this.storageService,
    required this.notificationService,
    required this.preferencesService,
    required this.premiumService,
    required this.habitService,
    required this.routineService,
    required this.journalService,
    required this.audioService,
    required this.widgetSyncService,
  });

  static AppServices of(BuildContext context) {
    return AppServicesScope.of(context);
  }

  static Future<AppServices> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final notif = NotificationService();
    await notif.init();

    final preferences = PreferencesService(prefs);
    final premium = PremiumService(prefs);
    await premium.init();
    final habit = HabitService(storage, notif);
    final routine = RoutineService(storage, habit);
    final journal = JournalService(storage);
    final audio = AudioService();
    final widgetSync = WidgetSyncService(habit, premium, preferences);
    await widgetSync.handlePendingWidgetLaunch();

    return AppServices._(
      sharedPreferences: prefs,
      storageService: storage,
      notificationService: notif,
      preferencesService: preferences,
      premiumService: premium,
      habitService: habit,
      routineService: routine,
      journalService: journal,
      audioService: audio,
      widgetSyncService: widgetSync,
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
    final scope = context.dependOnInheritedWidgetOfExactType<AppServicesScope>();
    if (scope == null) {
      throw StateError('AppServicesScope not found in widget tree');
    }
    return scope.services;
  }

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) => false;
}
