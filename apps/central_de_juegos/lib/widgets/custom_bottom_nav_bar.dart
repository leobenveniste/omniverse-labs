import 'package:flutter/material.dart';
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
    const navBgColor = AppTheme.surfaceDark;
    const goldColor = AppTheme.cyberGold;

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Base pill card
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: navBgColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppTheme.borderDark,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Left 1: Dados
                _buildNavItem(
                  index: 0,
                  icon: Icons.casino_outlined,
                  activeIcon: Icons.casino,
                  label: l10n.t('bottomDice'),
                ),
                // Left 2: Quién Empieza
                _buildNavItem(
                  index: 1,
                  icon: Icons.touch_app_outlined,
                  activeIcon: Icons.touch_app,
                  label: l10n.t('bottomWhoStarts'),
                ),

                // Center Spacer for elevated button
                const SizedBox(width: 58),

                // Right 1: Temporizador
                _buildNavItem(
                  index: 3,
                  icon: Icons.timer_outlined,
                  activeIcon: Icons.timer,
                  label: l10n.t('bottomTimer'),
                ),
                // Right 2: Moneda
                _buildNavItem(
                  index: 4,
                  icon: Icons.monetization_on_outlined,
                  activeIcon: Icons.monetization_on,
                  label: l10n.t('bottomCoin'),
                ),
              ],
            ),
          ),

          // Central Elevated Golden Button for "Juegos"
          Positioned(
            top: -10,
            child: GestureDetector(
              onTap: () => onItemSelected(2),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF00), Color(0xFFFFC700), Color(0xFFE5A800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withOpacity(selectedIndex == 2 ? 0.65 : 0.35),
                      blurRadius: 14,
                      spreadRadius: selectedIndex == 2 ? 2 : 0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.bgDark,
                    width: 3.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),

          // Active indicator dot under central button if index == 2
          if (selectedIndex == 2)
            Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: goldColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    const activeColor = AppTheme.cyberGold;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onItemSelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? activeColor : Colors.white38,
            ),
            const SizedBox(height: 3),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
