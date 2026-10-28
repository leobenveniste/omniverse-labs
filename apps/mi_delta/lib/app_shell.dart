import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_shell_scope.dart';
import 'core/theme/app_colors.dart';
import 'features/beneficios/agenda_screen.dart';
import 'features/beneficios/beneficios_screen.dart';
import 'features/beneficios/credencial_screen.dart';
import 'features/emergency/emergency_sheet.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/reclamos/reclamos_screen.dart';
import 'features/tramites/tramites_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Tabs:
  // 0: Turnos
  // 1: Reportes
  // 2: Home (Especial - Center FAB)
  // 3: Agenda
  // 4: Comunidad
  int _currentIndex = 2; // Home is initial active tab
  bool _isProfileOpen = false;
  double _sosHoldProgress = 0.0;
  Timer? _sosHoldTimer;

  late final List<ScrollController> _scrollControllers;

  @override
  void initState() {
    super.initState();
    _scrollControllers = List.generate(5, (_) => ScrollController());
  }

  @override
  void dispose() {
    _sosHoldTimer?.cancel();
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _isProfileOpen = false;
      _currentIndex = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index < _scrollControllers.length && _scrollControllers[index].hasClients) {
        _scrollControllers[index].animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _startSosHold() {
    HapticFeedback.mediumImpact();
    _sosHoldTimer?.cancel();
    _sosHoldTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _sosHoldProgress += 0.05 / 3.0; // 3 seconds to trigger
        if (_sosHoldProgress >= 1.0) {
          _sosHoldProgress = 1.0;
          timer.cancel();
          _triggerSosPanic();
        }
      });
      if ((_sosHoldProgress * 100).toInt() % 15 == 0) {
        HapticFeedback.lightImpact();
      }
    });
  }

  void _stopSosHold() {
    _sosHoldTimer?.cancel();
    if (_sosHoldProgress > 0.0 && _sosHoldProgress < 1.0) {
      setState(() {
        _sosHoldProgress = 0.0;
      });
    }
  }

  void _triggerSosPanic() {
    HapticFeedback.heavyImpact();
    setState(() => _sosHoldProgress = 0.0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF6B0F0B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text('ALERTA SOS ENVIADA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu señal de auxilio y geolocalización fueron despachadas al Centro de Operaciones Delta (COD) y SAME.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Un operador del municipio está intentando comunicarse a tu línea prioritaria.',
              style: TextStyle(color: Color(0xFFFFB4AB), fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              EmergencySheet.show(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6B0F0B),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
            label: const Text('Ver Teléfonos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _openProfile() {
    HapticFeedback.selectionClick();
    setState(() {
      _isProfileOpen = true;
    });
  }

  void _closeProfile() {
    HapticFeedback.selectionClick();
    setState(() {
      _isProfileOpen = false;
    });
  }

  void _openCredencial() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CredencialScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      // 0: Turnos
      TramitesScreen(
        scrollController: _scrollControllers[0],
      ),
      // 1: Reportes
      ReclamosScreen(
        scrollController: _scrollControllers[1],
        onAvatarTap: _openProfile,
      ),
      // 2: Home (Especial)
      HomeScreen(
        scrollController: _scrollControllers[2],
        onNavigateToTramites: () => _onTabSelected(0),
        onNavigateToReclamos: () => _onTabSelected(1),
        onNavigateToAgenda: () => _onTabSelected(3),
        onNavigateToSoyDelta: () => _onTabSelected(4),
        onNavigateToCredencial: _openCredencial,
        onNavigateToProfile: _openProfile,
      ),
      // 3: Agenda
      AgendaScreen(
        scrollController: _scrollControllers[3],
        onAvatarTap: _openProfile,
      ),
      // 4: Comunidad
      BeneficiosScreen(
        scrollController: _scrollControllers[4],
        onAvatarTap: _openProfile,
      ),
    ];

    final isHomeSelected = _currentIndex == 2;

    return AppShellScope(
      onOpenProfile: _openProfile,
      onOpenCredencial: _openCredencial,
      onSosTap: () {
        HapticFeedback.heavyImpact();
        EmergencySheet.show(context);
      },
      onSosLongPressStart: _startSosHold,
      onSosLongPressEnd: _stopSosHold,
      sosHoldProgress: _sosHoldProgress,
      onSelectTab: _onTabSelected,
      child: PopScope(
        canPop: !_isProfileOpen,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _isProfileOpen) {
            _closeProfile();
          }
        },
        child: Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
              if (_isProfileOpen)
                Positioned.fill(
                  child: ProfileScreen(
                    onBack: _closeProfile,
                  ),
                ),
              // Fullscreen interactive warning overlay during SOS Hold
              if (_sosHoldProgress > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 40),
                    color: const Color(0xFFBA1A1A).withValues(
                      alpha: (_sosHoldProgress * 0.72).clamp(0.0, 0.72),
                    ),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B0303).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFF5449),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFBA1A1A).withValues(alpha: 0.6),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFF5449).withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.emergency_rounded,
                                color: Color(0xFFFF5449),
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'ACTIVANDO ALERTA SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enviando auxilio en ${(3.0 - _sosHoldProgress * 3.0).clamp(0.0, 3.0).toStringAsFixed(1)}s',
                              style: const TextStyle(
                                color: Color(0xFFFFDAD6),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _sosHoldProgress,
                                minHeight: 10,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5449)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Soltá el botón para cancelar',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // --- CENTER SPECIAL "HOME" HERO BUTTON ---
        floatingActionButton: Semantics(
          button: true,
          label: 'Inicio',
          selected: isHomeSelected,
          child: Tooltip(
            message: 'Inicio',
            child: GestureDetector(
              onTap: () => _onTabSelected(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isHomeSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.darkPrimary,
                                  AppColors.darkSecondary,
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.darkSurfaceContainerHighest,
                                  AppColors.darkSurfaceContainerHigh,
                                ]
                              : [
                                  Colors.white,
                                  AppColors.surfaceContainerHigh,
                                ],
                        ),
                  border: Border.all(
                    color: isHomeSelected
                        ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.35))
                        : (isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.25)),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHomeSelected
                          ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.45))
                          : Colors.black.withValues(alpha: 0.12),
                      blurRadius: isHomeSelected ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isHomeSelected ? Icons.home_rounded : Icons.home_outlined,
                        color: isHomeSelected
                            ? (isDark ? const Color(0xFF002E46) : Colors.white)
                            : (isDark ? AppColors.darkPrimary : AppColors.primary),
                        size: 24,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Inicio',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isHomeSelected
                              ? (isDark ? const Color(0xFF002E46) : Colors.white)
                              : (isDark ? AppColors.darkPrimary : AppColors.primary),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        // --- BOTTOM APP BAR: [Turnos, Reportes] - HOME (ESPECIAL) - [Agenda, Comunidad] ---
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          elevation: 8,
          padding: EdgeInsets.zero,
          height: 62,
          color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest,
          child: Row(
            children: [
              // 1. Turnos
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Turnos',
                ),
              ),
              // 2. Reportes
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  icon: Icons.campaign_outlined,
                  activeIcon: Icons.campaign_rounded,
                  label: 'Reportes',
                ),
              ),
              // Center notch spacing for Special Home Hero Button
              const SizedBox(width: 52),
              // 3. Agenda
              Expanded(
                child: _buildNavItem(
                  index: 3,
                  icon: Icons.event_note_outlined,
                  activeIcon: Icons.event_note_rounded,
                  label: 'Agenda',
                ),
              ),
              // 4. Comunidad
              Expanded(
                child: _buildNavItem(
                  index: 4,
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                  label: 'Comunidad',
                ),
              ),
            ],
          ),
        ),
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
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
        : (isDark ? AppColors.darkOnSurfaceMuted : AppColors.onSurfaceMuted);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.darkPrimary.withValues(alpha: 0.16)
                          : AppColors.primary.withValues(alpha: 0.12))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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
