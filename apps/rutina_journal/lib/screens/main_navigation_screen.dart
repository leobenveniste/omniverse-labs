import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/habit_service.dart';
import '../services/journal_service.dart';
import '../services/preferences_service.dart';
import '../services/routine_service.dart';
import '../services/storage_service.dart';
import '../utils/haptics_helper.dart';
import 'analytics_screen.dart';
import 'journal_screen.dart';
import 'routines_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final PreferencesService? prefs;
  final HabitService? habitService;
  final RoutineService? routineService;
  final JournalService? journalService;
  final StorageService? storage;

  const MainNavigationScreen({
    super.key,
    this.prefs,
    this.habitService,
    this.routineService,
    this.journalService,
    this.storage,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Retrieve inherited or injected services
    AppServices? scopeServices;
    try {
      scopeServices = AppServicesScope.of(context);
    } catch (_) {}

    final habitService = widget.habitService ?? scopeServices?.habitService;
    final routineService = widget.routineService ?? scopeServices?.routineService;
    final journalService = widget.journalService ?? scopeServices?.journalService;
    final prefs = widget.prefs ?? scopeServices?.preferencesService;
    final storage = widget.storage ?? scopeServices?.storageService;

    if (habitService == null || routineService == null || journalService == null || prefs == null || storage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      TodayScreen(habitService: habitService, routineService: routineService),
      RoutinesScreen(routineService: routineService),
      JournalScreen(journalService: journalService),
      AnalyticsScreen(habitService: habitService, journalService: journalService),
      SettingsScreen(prefs: prefs, storage: storage, habitService: habitService),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          HapticsHelper.selection();
          setState(() => _currentIndex = idx);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today_rounded),
            label: l10n.t('navToday'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.repeat_outlined),
            selectedIcon: const Icon(Icons.repeat_rounded),
            label: l10n.t('navRoutines'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories_rounded),
            label: l10n.t('navJournal'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_rounded),
            selectedIcon: const Icon(Icons.show_chart_rounded),
            label: l10n.t('navAnalytics'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.t('navSettings'),
          ),
        ],
      ),
    );
  }
}
