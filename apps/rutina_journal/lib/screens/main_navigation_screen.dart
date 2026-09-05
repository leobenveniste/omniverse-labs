import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/habit_service.dart';
import '../services/journal_service.dart';
import '../services/preferences_service.dart';
import '../services/routine_service.dart';
import '../services/storage_service.dart';
import '../utils/haptics_helper.dart';
import '../widgets/focus_zone_screen.dart';
import '../widgets/paywall_sheet.dart';
import 'analytics_screen.dart';
import 'journal_screen.dart';
import 'routines_screen.dart';
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

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _handledInitialWidgetLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWidgetDeepLink();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkWidgetDeepLink();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkWidgetDeepLink() async {
    if (!mounted) return;
    try {
      final syncService = AppServices.of(context).widgetSyncService;
      final targetScreen = await syncService.checkPendingOpenScreen();
      if (!mounted) return;

      if (targetScreen == 'focus_zone') {
        final premiumService = AppServices.of(context).premiumService;
        if (premiumService.canStartFocusSession) {
          FocusZoneScreen.show(context);
        } else {
          final l10n = AppLocalizations.of(context);
          PaywallSheet.show(
            context,
            customReason: l10n.t('proLimitFocusMsg'),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      AnalyticsScreen(
        habitService: habitService,
        journalService: journalService,
        prefs: prefs,
        storage: storage,
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.38),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticsHelper.medium();
              final premiumService = AppServices.of(context).premiumService;
              if (!premiumService.canStartFocusSession) {
                PaywallSheet.show(
                  context,
                  customReason: l10n.t('proLimitFocusMsg'),
                );
                return;
              }
              FocusZoneScreen.show(context);
            },
            child: Tooltip(
              message: l10n.t('focusZoneTitle'),
              child: Icon(
                Icons.self_improvement_rounded,
                color: theme.colorScheme.onPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        elevation: 8,
        padding: EdgeInsets.zero,
        height: 64,
        color: theme.colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.today_outlined,
              activeIcon: Icons.today_rounded,
              label: l10n.t('navToday'),
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.repeat_outlined,
              activeIcon: Icons.repeat_rounded,
              label: l10n.t('navRoutines'),
            ),
            const SizedBox(width: 48), // Center spacing for protruding Focus Zone FAB
            _buildNavItem(
              index: 2,
              icon: Icons.auto_stories_outlined,
              activeIcon: Icons.auto_stories_rounded,
              label: l10n.t('navJournal'),
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.show_chart_rounded,
              activeIcon: Icons.show_chart_rounded,
              label: l10n.t('navAnalytics'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () {
            HapticsHelper.selection();
            setState(() => _currentIndex = index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
