import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const goldColor = AppTheme.cyberGold;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          elevation: 8,
          padding: EdgeInsets.zero,
          height: 64,
          color: AppTheme.surfaceDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left 1: Dados
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.casino_outlined,
                activeIcon: Icons.casino_rounded,
                label: l10n.t('bottomDice'),
              ),
              // Left 2: Quién Empieza
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.touch_app_outlined,
                activeIcon: Icons.touch_app_rounded,
                label: l10n.t('bottomWhoStarts'),
              ),

              // Center Spacer for elevated button
              const SizedBox(width: 48),

              // Right 1: Temporizador
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.timer_outlined,
                activeIcon: Icons.timer_rounded,
                label: l10n.t('bottomTimer'),
              ),
              // Right 2: Moneda
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.monetization_on_outlined,
                activeIcon: Icons.monetization_on_rounded,
                label: l10n.t('bottomCoin'),
              ),
            ],
          ),
        ),

        // Central Protruding Button for "Juegos"
        Positioned(
          top: -16,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onItemSelected(2);
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDF00), Color(0xFFFFC700), Color(0xFFE5A800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldColor.withValues(alpha: selectedIndex == 2 ? 0.65 : 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.surfaceDark,
                  width: 3.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.grid_view_rounded,
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    const activeColor = AppTheme.cyberGold;
    final inactiveColor = Colors.white.withValues(alpha: 0.6);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onItemSelected(index);
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
                  color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
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
