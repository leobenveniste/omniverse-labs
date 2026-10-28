import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/guide/guide_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../repositories/storage_repository.dart';
import 'packing/packing_studio_screen.dart';
import 'passport/passport_view_screen.dart';
import 'pro/pro_paywall_modal.dart';
import 'settings/settings_screen.dart';
import 'tools/travel_tools_screen.dart';
import 'trips/trips_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  final StorageRepository storage;
  final ThemeController themeController;
  final LocaleController localeController;
  final GuideController guideController;

  const HomeNavigationScreen({
    super.key,
    required this.storage,
    required this.themeController,
    required this.localeController,
    required this.guideController,
  });

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDailyPromo());
  }

  Future<void> _checkDailyPromo() async {
    final shouldShow = await widget.storage.shouldShowDailyPromo();
    if (shouldShow && mounted) {
      await widget.storage.markDailyPromoSeen();
      if (mounted) {
        ProPaywallModal.show(context, widget.storage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Screens:
    // 0: Passport (Pasaporte)
    // 1: Packing Studio (Estudio de Empaque)
    // 2: Trips (Hero Center Button - Viajes & Pases)
    // 3: Toolkit (Herramientas / Bolsillo)
    // 4: Settings (Ajustes)
    final screens = [
      PassportViewScreen(
        storage: widget.storage,
        guideController: widget.guideController,
      ),
      PackingStudioScreen(
        storage: widget.storage,
        guideController: widget.guideController,
      ),
      TripsScreen(
        storage: widget.storage,
        guideController: widget.guideController,
      ),
      TravelToolsScreen(
        guideController: widget.guideController,
        storage: widget.storage,
      ),
      SettingsScreen(
        themeController: widget.themeController,
        localeController: widget.localeController,
        guideController: widget.guideController,
        storage: widget.storage,
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.goldFoilLight, AppColors.goldFoil]
                : [AppColors.burgundyBase, AppColors.burgundyDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.goldFoil : AppColors.burgundyBase).withValues(alpha: 0.38),
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
              HapticFeedback.mediumImpact();
              if (_currentIndex != 2) {
                setState(() => _currentIndex = 2);
              }
            },
            child: Tooltip(
              message: t.t('nav_trips'),
              child: Icon(
                Icons.airplane_ticket_rounded,
                color: isDark ? AppColors.darkBackground : Colors.white,
                size: 26,
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
        color: navBg,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.badge_outlined,
              activeIcon: Icons.badge_rounded,
              label: t.t('nav_passport'),
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.luggage_outlined,
              activeIcon: Icons.luggage_rounded,
              label: t.t('nav_packing'),
            ),
            const SizedBox(width: 48), // Center spacing for notched Trips button
            _buildNavItem(
              index: 3,
              icon: Icons.workspaces_outline,
              activeIcon: Icons.workspaces_rounded,
              label: t.t('nav_tools'),
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: t.t('nav_settings'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
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
                  color: isSelected ? goldAccent.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? goldAccent : textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? goldAccent : textSecondary,
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
