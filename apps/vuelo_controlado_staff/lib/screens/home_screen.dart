import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/motion_components.dart';
import 'events/events_list_screen.dart';
import 'events/event_detail_screen.dart';
import 'cases/cases_hub_screen.dart';
import 'cases/case_form_screen.dart';
import 'profile/profile_screen.dart';
import 'help/help_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tabs:
  // 0: Eventos
  // 1: Casos
  // 2: Perfil (Center Hero FAB - Botón Principal - Pantalla Inicial)
  // 3: Ayuda
  // 4: Configuración
  int _currentIndex = 2;

  // Subnavegación persistente en tabs
  String? _selectedEventId;
  EventModel? _caseEventTarget;
  CaseModel? _editingCase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    final bool canSystemPop = _currentIndex == 2;

    return PopScope(
      canPop: canSystemPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex == 0 && _selectedEventId != null) {
          setState(() => _selectedEventId = null);
        } else if (_currentIndex == 1 && _caseEventTarget != null) {
          setState(() {
            _caseEventTarget = null;
            _editingCase = null;
          });
        } else if (_currentIndex != 2) {
          setState(() => _currentIndex = 2);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: AppBackground(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: _buildCurrentTab(),
            ),
          ),
        ),
        // Botón Principal Central: PERFIL (M3 Expressive Hero FAB con micro-rebote)
        floatingActionButton: PressableScale(
          targetScale: 0.92,
          semanticLabel: 'Mi Credencial y Perfil',
          onTap: () {
            HapticFeedback.mediumImpact();
            if (_currentIndex != 2) {
              setState(() => _currentIndex = 2);
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  AppTheme.cyanAccent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.42),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Tooltip(
              message: 'Mi Credencial y Perfil',
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _currentIndex == 2
                        ? Icons.badge_rounded
                        : Icons.badge_outlined,
                    key: ValueKey(_currentIndex == 2),
                    color: const Color(0xFF121212),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 64,
          color: theme.colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tab 0: Eventos
              _buildNavItem(
                index: 0,
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month_rounded,
                label: 'Eventos',
              ),
              // Tab 1: Casos
              _buildNavItem(
                index: 1,
                icon: Icons.medical_services_outlined,
                activeIcon: Icons.medical_services_rounded,
                label: 'Casos',
              ),
              // Espacio central para el botón principal Perfil en el notch
              const SizedBox(width: 56),
              // Tab 3: Ayuda
              _buildNavItem(
                index: 3,
                icon: Icons.help_outline_rounded,
                activeIcon: Icons.help_rounded,
                label: 'Ayuda',
              ),
              // Tab 4: Configuración
              _buildNavItem(
                index: 4,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Ajustes',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: _selectedEventId != null
              ? EventDetailScreen(
                  key: ValueKey('event_detail_$_selectedEventId'),
                  eventId: _selectedEventId!,
                  onBack: () => setState(() => _selectedEventId = null),
                  onOpenCaseForm: (event) {
                    setState(() {
                      _currentIndex = 1;
                      _caseEventTarget = event;
                      _editingCase = null;
                    });
                  },
                )
              : EventsListScreen(
                  key: const ValueKey('events_list'),
                  onSelectEvent: (eventId) {
                    setState(() => _selectedEventId = eventId);
                  },
                ),
        );
      case 1:
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: _caseEventTarget != null
              ? CaseFormScreen(
                  key: ValueKey(
                    'case_form_${_caseEventTarget!.id}_${_editingCase?.id ?? "new"}',
                  ),
                  event: _caseEventTarget!,
                  existingCase: _editingCase,
                  onBack: () => setState(() {
                    _caseEventTarget = null;
                    _editingCase = null;
                  }),
                )
              : CasesHubScreen(
                  key: const ValueKey('cases_hub'),
                  onOpenCaseForm: (event, existingCase) {
                    setState(() {
                      _caseEventTarget = event;
                      _editingCase = existingCase;
                    });
                  },
                ),
        );
      case 2:
        return const ProfileScreen();
      case 3:
        return const HelpScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const ProfileScreen();
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (index == 0) {
                _selectedEventId = null;
              } else if (index == 1) {
                _caseEventTarget = null;
                _editingCase = null;
              }
              _currentIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1.12 : 1.0,
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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
      ),
    );
  }
}
