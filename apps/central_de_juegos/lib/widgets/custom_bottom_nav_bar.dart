import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBgColor = isDark ? const Color(0xFF1E2128) : Colors.white;
    const orangeColor = Color(0xFFFF6D00);

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Base pill card with subtle shadow and border
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: navBgColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Left 1: Dados
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.casino_outlined,
                  activeIcon: Icons.casino,
                  label: 'Dados',
                ),
                // Left 2: Quién Empieza
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.touch_app_outlined,
                  activeIcon: Icons.touch_app,
                  label: 'Quién',
                ),

                // Center Spacer for elevated button
                const SizedBox(width: 58),

                // Right 1: Temporizador
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.timer_outlined,
                  activeIcon: Icons.timer,
                  label: 'Tiempo',
                ),
                // Right 2: Moneda
                _buildNavItem(
                  context,
                  index: 4,
                  icon: Icons.monetization_on_outlined,
                  activeIcon: Icons.monetization_on,
                  label: 'Moneda',
                ),
              ],
            ),
          ),

          // Central Elevated Orange Button for "Juegos"
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
                    colors: [Color(0xFFFF8A65), Color(0xFFFF5722), Color(0xFFE64A19)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: orangeColor.withOpacity(selectedIndex == 2 ? 0.6 : 0.35),
                      blurRadius: 14,
                      spreadRadius: selectedIndex == 2 ? 2 : 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 3.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
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
                  color: orangeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

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
              color: isSelected
                  ? activeColor
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 3),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
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
