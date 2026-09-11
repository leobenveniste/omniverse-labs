import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../providers/security_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/trade_provider.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../calculator/screens/position_calculator_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../operations/screens/operations_list_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../l10n/app_localizations.dart';

class MainShellScreen extends StatefulWidget {
  final TradeProvider tradeProvider;
  final SettingsProvider settingsProvider;
  final SecurityProvider securityProvider;

  const MainShellScreen({
    super.key,
    required this.tradeProvider,
    required this.settingsProvider,
    required this.securityProvider,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  // Tabs:
  // 0: Operations
  // 1: Calculator
  // 2: Dashboard (Center Docked)
  // 3: Analytics
  // 4: Settings
  int _currentIndex = 2; // Dashboard center selected by default

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isDashboardSelected = _currentIndex == 2;

    final screens = <Widget>[
      OperationsListScreen(
        tradeProvider: widget.tradeProvider,
        settingsProvider: widget.settingsProvider,
      ),
      PositionCalculatorScreen(
        settingsProvider: widget.settingsProvider,
        tradeProvider: widget.tradeProvider,
      ),
      DashboardScreen(
        tradeProvider: widget.tradeProvider,
        settingsProvider: widget.settingsProvider,
        onNavigateToOperations: () {
          setState(() => _currentIndex = 0);
        },
      ),
      AnalyticsScreen(
        tradeProvider: widget.tradeProvider,
        settingsProvider: widget.settingsProvider,
      ),
      SettingsScreen(
        settingsProvider: widget.settingsProvider,
        securityProvider: widget.securityProvider,
        tradeProvider: widget.tradeProvider,
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // Center Docked Dashboard Button (Ritmo style with gradient & glow)
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.centerFabGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDashboardSelected ? colors.secondary : colors.primary)
                  .withValues(alpha: 0.42),
              blurRadius: 12,
              spreadRadius: isDashboardSelected ? 2 : 0,
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
              setState(() => _currentIndex = 2);
            },
            child: Tooltip(
              message: 'Dashboard Cockpit',
              child: Icon(
                Icons.insights_rounded,
                color: Colors.white,
                size: isDashboardSelected ? 30 : 28,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Circular notched bottom app bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        elevation: 12,
        padding: EdgeInsets.zero,
        height: 64,
        color: colors.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left 1: Operations
            _buildNavItem(
              index: 0,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: l10n.t('navOperations'),
              colors: colors,
            ),
            // Left 2: Calculator
            _buildNavItem(
              index: 1,
              icon: Icons.calculate_outlined,
              activeIcon: Icons.calculate_rounded,
              label: l10n.t('navCalculator'),
              colors: colors,
            ),

            // Center Spacing for protruding Dashboard FAB
            const SizedBox(width: 48),

            // Right 1: Analytics
            _buildNavItem(
              index: 3,
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics_rounded,
              label: l10n.t('navAnalytics'),
              colors: colors,
            ),
            // Right 2: Settings
            _buildNavItem(
              index: 4,
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: l10n.t('navSettings'),
              colors: colors,
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
    required AppColors colors,
  }) {
    final isSelected = _currentIndex == index;
    final iconColor = isSelected ? colors.primary : colors.textTertiary;

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
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption(
                  isSelected ? colors.textPrimary : colors.textTertiary,
                  isBold: isSelected,
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
