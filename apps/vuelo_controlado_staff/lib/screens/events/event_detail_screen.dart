import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/case_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/event_banner_image.dart';
import '../../widgets/motion_components.dart';
import '../cases/case_form_screen.dart';
import '../cases/event_cases_screen.dart';
import 'create_event_screen.dart';
import 'event_unified_report_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final VoidCallback? onBack;
  final void Function(EventModel)? onOpenCaseForm;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.onBack,
    this.onOpenCaseForm,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isTogglingStaff = false;
  bool _isDeleting = false;

  String _formatDetailDate(DateTime date) {
    try {
      final formatter = DateFormat('EEEE d \'de\' MMMM \'de\' yyyy', 'es');
      final formatted = formatter.format(date);
      if (formatted.isNotEmpty) {
        return formatted[0].toUpperCase() + formatted.substring(1);
      }
      return formatted;
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _openGoogleMaps(String location, String? address) async {
    HapticFeedback.lightImpact();
    final query = (address != null && address.trim().isNotEmpty)
        ? '$location, $address'
        : location;
    final encoded = Uri.encodeComponent(query);
    final webUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    final geoUri = Uri.parse('geo:0,0?q=$encoded');

    try {
      bool launched = false;
      try {
        launched =
            await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        try {
          launched =
              await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      if (!launched) {
        try {
          launched = await launchUrl(webUri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el mapa.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el mapa.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _handleBack() {
    HapticFeedback.selectionClick();
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _toggleStaffMembership(
    EventModel event,
    UserModel currentUser,
    bool isStaff,
  ) async {
    if (_isTogglingStaff) return;
    HapticFeedback.mediumImpact();
    final eventService = context.read<EventService>();

    if (isStaff) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Dejar Evento'),
          content: const Text(
            '¿Estás seguro de que querés salir del staff asignado a este evento?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      setState(() => _isTogglingStaff = true);
      await eventService.leaveEvent(event.id, currentUser.id);
      if (mounted) {
        setState(() => _isTogglingStaff = false);
      }
    } else {
      setState(() => _isTogglingStaff = true);
      final messenger = ScaffoldMessenger.of(context);
      await eventService.joinEvent(event.id, currentUser.id);
      if (!mounted) return;
      setState(() => _isTogglingStaff = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ ¡Te sumaste al staff de este evento!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    }
  }

  Future<void> _openEditEvent(BuildContext context, EventModel event) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(event: event),
      ),
    );
  }

  Future<void> _confirmDeleteEvent(
    BuildContext context,
    EventModel event,
    UserModel currentUser,
  ) async {
    if (_isDeleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
              SizedBox(width: 8),
              Text('Eliminar Evento'),
            ],
          ),
          content: Text(
            '¿Estás seguro de que querés eliminar permanentemente el evento "${event.name}"?\nEsta acción no se puede deshacer.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      setState(() => _isDeleting = true);
      final eventService = context.read<EventService>();
      final success = await eventService.deleteEvent(event.id, currentUser);
      if (mounted && context.mounted) {
        setState(() => _isDeleting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Evento eliminado correctamente'),
              backgroundColor: AppTheme.neonGreen,
            ),
          );
          _handleBack();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tenés permisos para eliminar este evento.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddPairDialog(
    BuildContext context,
    EventModel event,
    List<UserModel> staffUsers,
    UserModel currentUser,
  ) async {
    // Filtrar miembros anotados que aún no tienen pareja asignada
    final availableUsers =
        staffUsers.where((u) => event.getPairForUser(u.id) == null).toList();

    if (availableUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se requieren al menos 2 miembros del staff sin pareja asignada para armar una nueva pareja.',
          ),
          backgroundColor: AppTheme.amberWarning,
        ),
      );
      return;
    }

    String? selectedUser1Id = availableUsers[0].id;
    String? selectedUser2Id = availableUsers[1].id;
    final theme = Theme.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final remainingUsers =
                availableUsers.where((u) => u.id != selectedUser1Id).toList();
            if (!remainingUsers.any((u) => u.id == selectedUser2Id)) {
              selectedUser2Id =
                  remainingUsers.isNotEmpty ? remainingUsers.first.id : null;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        style: AppTheme.headerIconButtonStyle(ctx),
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Armar Pareja de Guardia / Ronda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seleccioná los 2 miembros del staff que formarán la pareja para las rondas de este evento:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor(ctx),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Selector Miembro 1
                  DropdownButtonFormField<String>(
                    initialValue: selectedUser1Id,
                    decoration: const InputDecoration(
                      labelText: 'Primer Miembro',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    items: availableUsers.map((u) {
                      return DropdownMenuItem(
                        value: u.id,
                        child: Text(u.fullName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedUser1Id = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Selector Miembro 2
                  DropdownButtonFormField<String>(
                    initialValue: selectedUser2Id,
                    decoration: const InputDecoration(
                      labelText: 'Segundo Miembro (Pareja)',
                      prefixIcon: Icon(Icons.people_outline_rounded),
                    ),
                    items: remainingUsers.map((u) {
                      return DropdownMenuItem(
                        value: u.id,
                        child: Text(u.fullName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedUser2Id = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(ctx),
                      foregroundColor: AppTheme.onPrimaryColor(ctx),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: (selectedUser1Id == null ||
                            selectedUser2Id == null ||
                            selectedUser1Id == selectedUser2Id)
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            final u1 = availableUsers
                                .firstWhere((u) => u.id == selectedUser1Id);
                            final u2 = availableUsers
                                .firstWhere((u) => u.id == selectedUser2Id);
                            final eventService = context.read<EventService>();
                            final ok = await eventService.addEventPair(
                              eventId: event.id,
                              user1Id: u1.id,
                              user1Name: u1.fullName,
                              user2Id: u2.id,
                              user2Name: u2.fullName,
                              currentUser: currentUser,
                            );
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              if (ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '✓ Pareja armada: ${u1.fullName} & ${u2.fullName}'),
                                    backgroundColor: AppTheme.neonGreen,
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Guardar Pareja'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddRoundBottomSheet(
    BuildContext context,
    EventModel event,
    UserModel currentUser,
  ) async {
    final theme = Theme.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final assignedPair = event.getPairForUser(currentUser.id);
    final partnerName = assignedPair?.getPartnerName(currentUser.id);

    int detectedCases = 0;
    int calls = 0;
    final observationsController = TextEditingController();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          style: AppTheme.headerIconButtonStyle(ctx),
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Cerrar',
                          onPressed:
                              isSaving ? null : () => Navigator.of(ctx).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Registrar Ronda de Guardia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta de Identificación del Miembro y Pareja
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer(ctx),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor(ctx)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 22,
                            color: AppTheme.primaryColor(ctx),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.fullName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  partnerName != null
                                      ? 'Pareja de ronda: $partnerName'
                                      : 'Sin pareja de ronda asignada',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: partnerName != null
                                        ? AppTheme.neonGreen
                                        : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contadores de Rondas (Casos Detectados y Llamados)
                    Row(
                      children: [
                        // Casos Detectados
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer(ctx),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppTheme.borderColor(ctx)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Casos Detectados',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      style:
                                          AppTheme.headerIconButtonStyle(ctx),
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: (detectedCases > 0 && !isSaving)
                                          ? () {
                                              HapticFeedback.selectionClick();
                                              setModalState(
                                                  () => detectedCases--);
                                            }
                                          : null,
                                    ),
                                    Text(
                                      '$detectedCases',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.neonGreen,
                                      ),
                                    ),
                                    IconButton(
                                      style:
                                          AppTheme.headerIconButtonStyle(ctx),
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: !isSaving
                                          ? () {
                                              HapticFeedback.selectionClick();
                                              setModalState(
                                                  () => detectedCases++);
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Llamados
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer(ctx),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppTheme.borderColor(ctx)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Llamados',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      style:
                                          AppTheme.headerIconButtonStyle(ctx),
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: (calls > 0 && !isSaving)
                                          ? () {
                                              HapticFeedback.selectionClick();
                                              setModalState(() => calls--);
                                            }
                                          : null,
                                    ),
                                    Text(
                                      '$calls',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.skyBlue,
                                      ),
                                    ),
                                    IconButton(
                                      style:
                                          AppTheme.headerIconButtonStyle(ctx),
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: !isSaving
                                          ? () {
                                              HapticFeedback.selectionClick();
                                              setModalState(() => calls++);
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Observaciones del recorrido
                    Text(
                      'Observaciones del Recorrido',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: observationsController,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Ej: Ronda general por pista y sector de hidratación. El público se encuentra receptivo.',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Guardar
                    PressableScale(
                      onTap: isSaving
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              setModalState(() => isSaving = true);
                              final eventService =
                                  context.read<EventService>();
                              final ok = await eventService.addEventRoundLog(
                                eventId: event.id,
                                detectedCasesCount: detectedCases,
                                callsCount: calls,
                                observations: observationsController.text,
                                currentUser: currentUser,
                              );
                              if (ctx.mounted) {
                                setModalState(() => isSaving = false);
                                Navigator.of(ctx).pop();
                                if (ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          '✓ Ronda registrada exitosamente.'),
                                      backgroundColor: AppTheme.neonGreen,
                                    ),
                                  );
                                }
                              }
                            },
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor(ctx),
                          foregroundColor: AppTheme.onPrimaryColor(ctx),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                setModalState(() => isSaving = true);
                                final eventService =
                                    context.read<EventService>();
                                final ok = await eventService.addEventRoundLog(
                                  eventId: event.id,
                                  detectedCasesCount: detectedCases,
                                  callsCount: calls,
                                  observations: observationsController.text,
                                  currentUser: currentUser,
                                );
                                if (ctx.mounted) {
                                  setModalState(() => isSaving = false);
                                  Navigator.of(ctx).pop();
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            '✓ Ronda registrada exitosamente.'),
                                        backgroundColor: AppTheme.neonGreen,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                            isSaving ? 'Guardando...' : 'Guardar Ronda'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final eventService = context.watch<EventService>();
    final caseService = context.watch<CaseService>();
    final currentUser = authService.currentUser;

    final event = eventService.getEventById(widget.eventId);
    if (event == null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            titleSpacing: 8,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                style: AppTheme.headerIconButtonStyle(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'Volver',
                onPressed: _handleBack,
              ),
            ),
            title: const AppHeaderTitle(title: 'Evento'),
          ),
          body: Center(
            child: Text(
              'Evento no encontrado o eliminado.',
              style: TextStyle(color: AppTheme.textSecondaryColor(context)),
            ),
          ),
        ),
      );
    }

    final isStaff = currentUser != null && event.isUserInStaff(currentUser.id);
    final canManageProductionReport = currentUser != null &&
        (currentUser.isSuperAdmin || currentUser.hasRole(AppRoles.produccion));
    final canManagePairs = currentUser != null &&
        (currentUser.isSuperAdmin ||
            currentUser.hasRole(AppRoles.organizacion) ||
            currentUser.hasRole(AppRoles.produccion));
    final isStarted = event.hasStarted;
    final cases = caseService.getCasesForEvent(event.id);
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final surfaceContainer = AppTheme.surfaceContainer(context);
    final borderColor = AppTheme.borderColor(context);

    // Buscar datos de miembros sumados
    final allUsers = authService.users;
    final staffUsers =
        allUsers.where((u) => event.staffIds.contains(u.id)).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          titleSpacing: 8,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              style: AppTheme.headerIconButtonStyle(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              tooltip: 'Volver',
              onPressed: _handleBack,
            ),
          ),
          title: const AppHeaderTitle(title: 'Evento'),
          actions: [
            if (currentUser != null)
              FilledButton(
                style: AppTheme.headerActionButtonStyle(
                  context,
                  isFilled: !isStaff,
                ),
                onPressed: _isTogglingStaff
                    ? null
                    : () => _toggleStaffMembership(event, currentUser, isStaff),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isTogglingStaff
                      ? SizedBox(
                          key: const ValueKey('staff_loading'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            strokeCap: StrokeCap.round,
                            color: isStaff
                                ? primary
                                : AppTheme.onPrimaryColor(context),
                          ),
                        )
                      : Row(
                          key: ValueKey('staff_state_$isStaff'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isStaff
                                  ? Icons.check_rounded
                                  : Icons.person_add_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(isStaff ? 'Sumado' : 'Sumarme'),
                          ],
                        ),
                ),
              ),
            if (currentUser != null && currentUser.canCreateEvents) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Opciones del Evento',
                style: AppTheme.headerIconButtonStyle(context),
                icon: _isDeleting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          color: primary,
                        ),
                      )
                    : const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditEvent(context, event);
                  } else if (value == 'delete') {
                    _confirmDeleteEvent(context, event, currentUser);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: primary),
                        const SizedBox(width: 12),
                        const Text(
                          'Editar Evento',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.errorRed,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Eliminar Evento',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.paddingOf(context).bottom + 96,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner superior cuando el usuario ya está sumado al evento
                  if (isStaff) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Estás sumado como staff en este evento',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Banner de Pareja de Ronda del usuario actual
                  if (currentUser != null &&
                      (isStaff || currentUser.isSuperAdmin)) ...[
                    Builder(
                      builder: (context) {
                        final myPair = event.getPairForUser(currentUser.id);
                        final partnerName =
                            myPair?.getPartnerName(currentUser.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: partnerName != null
                                ? AppTheme.neonGreen.withValues(alpha: 0.12)
                                : surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: partnerName != null
                                  ? AppTheme.neonGreen.withValues(alpha: 0.5)
                                  : borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                partnerName != null
                                    ? Icons.people_alt_rounded
                                    : Icons.person_outline_rounded,
                                color: partnerName != null
                                    ? AppTheme.neonGreen
                                    : textSecondary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      partnerName != null
                                          ? 'Tu pareja de guardia / ronda:'
                                          : 'Pareja de guardia / ronda:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      partnerName ??
                                          'Aún no tenés pareja de ronda asignada.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: partnerName != null
                                            ? textPrimary
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // Tarjeta de Información Principal
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.imageUrl != null &&
                            event.imageUrl!.trim().isNotEmpty)
                          EventBannerImage(
                            imageSource: event.imageUrl,
                            height: 160,
                            width: double.infinity,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.name,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimary,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isStarted
                                          ? primary.withValues(alpha: 0.16)
                                          : surfaceContainer,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isStarted ? primary : borderColor,
                                      ),
                                    ),
                                    child: Text(
                                      event.statusText.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isStarted ? primary : textSecondary,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Dirección como Link a Google Maps
                              if (event.location.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _openGoogleMaps(
                                    event.location,
                                    event.address,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.place_outlined,
                                          size: 16,
                                          color: primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            (event.address != null &&
                                                    event.address!
                                                        .trim()
                                                        .isNotEmpty)
                                                ? '${event.location} • ${event.address}'
                                                : event.location,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.open_in_new_rounded,
                                          size: 14,
                                          color: primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    size: 16,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatDetailDate(event.date),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Horarios en orden: Inicio, Puertas, Cierre
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: surfaceContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _HorarioCol(
                                      label: 'Inicio',
                                      time: '${event.startTime} hs',
                                      icon: Icons.play_arrow_outlined,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: borderColor,
                                    ),
                                    _HorarioCol(
                                      label: 'Puertas',
                                      time: '${event.doorsOpenTime} hs',
                                      icon: Icons.meeting_room_outlined,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: borderColor,
                                    ),
                                    _HorarioCol(
                                      label: 'Cierre',
                                      time: '${event.endTime} hs',
                                      icon: Icons.nightlight_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SECCIÓN: REGISTRO UNIFICADO POR EVENTO (Exclusivo Rol Producción)
                  if (canManageProductionReport) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: event.unifiedReport != null
                              ? AppTheme.emeraldDark
                              : primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in_outlined,
                                      color: primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Registro por Evento',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'PRODUCCIÓN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: primary,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.unifiedReport != null
                                  ? 'Completado por ${event.unifiedReport!.completedByUserName} • ${DateFormat('dd/MM/yyyy HH:mm').format(event.unifiedReport!.completedAt)}'
                                  : 'Pendiente de carga. Información técnica, médica y operativa del evento.',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            PressableScale(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EventUnifiedReportScreen(
                                      event: event,
                                    ),
                                  ),
                                );
                              },
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: event.unifiedReport != null
                                      ? surfaceContainer
                                      : primary,
                                  foregroundColor: event.unifiedReport != null
                                      ? textPrimary
                                      : AppTheme.onPrimaryColor(context),
                                  side: BorderSide(
                                    color: event.unifiedReport != null
                                        ? borderColor
                                        : Colors.transparent,
                                  ),
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                icon: Icon(
                                  event.unifiedReport != null
                                      ? Icons.edit_note_rounded
                                      : Icons.add_chart_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  event.unifiedReport != null
                                      ? 'Editar Registro de Producción'
                                      : 'Cargar Registro por Evento',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EventUnifiedReportScreen(
                                        event: event,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SECCIÓN: PAREJAS DE GUARDIA / RONDA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Parejas de Ronda (${event.pairs.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (canManagePairs)
                        PressableScale(
                          onTap: () => _showAddPairDialog(
                            context,
                            event,
                            staffUsers,
                            currentUser,
                          ),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Armar Pareja',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () => _showAddPairDialog(
                              context,
                              event,
                              staffUsers,
                              currentUser,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (event.pairs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 20, color: textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                canManagePairs
                                    ? 'Aún no se armaron parejas. Los roles de Organización y Producción pueden armarlas aquí.'
                                    : 'Aún no se asignaron parejas para este evento.',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: event.pairs.length,
                      itemBuilder: (context, index) {
                        final pair = event.pairs[index];
                        final isMyPair = currentUser != null &&
                            pair.containsUser(currentUser.id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isMyPair
                                  ? AppTheme.neonGreen.withValues(alpha: 0.6)
                                  : borderColor,
                              width: isMyPair ? 1.5 : 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: surfaceContainer,
                                  child: Text(
                                    pair.user1Name.isNotEmpty
                                        ? pair.user1Name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pair.user1Name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 18,
                                    color: primary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    pair.user2Name,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: surfaceContainer,
                                  child: Text(
                                    pair.user2Name.isNotEmpty
                                        ? pair.user2Name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (canManagePairs) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppTheme.errorRed,
                                    ),
                                    tooltip: 'Desarmar pareja',
                                    onPressed: () async {
                                      HapticFeedback.lightImpact();
                                      final eventService =
                                          context.read<EventService>();
                                      await eventService.removeEventPair(
                                        eventId: event.id,
                                        pairId: pair.id,
                                        currentUser: currentUser,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // SECCIÓN: REGISTRO DE RONDAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Registro de Rondas (${event.roundLogs.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (currentUser != null &&
                          (isStaff || currentUser.isSuperAdmin))
                        PressableScale(
                          onTap: () => _showAddRoundBottomSheet(
                            context,
                            event,
                            currentUser,
                          ),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor:
                                  AppTheme.onPrimaryColor(context),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.add_task_rounded, size: 16),
                            label: const Text(
                              'Nueva Ronda',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () => _showAddRoundBottomSheet(
                              context,
                              event,
                              currentUser,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (event.roundLogs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.directions_walk_rounded,
                                size: 20, color: textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                (isStaff ||
                                        (currentUser?.isSuperAdmin ?? false))
                                    ? 'Aún no se registraron rondas. Tocá "Nueva Ronda" para asentar un recorrido de guardia.'
                                    : 'Aún no se han registrado rondas en este evento.',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: event.roundLogs.length,
                      itemBuilder: (context, index) {
                        final log = event.roundLogs[index];
                        final timeStr =
                            DateFormat('HH:mm').format(log.timestamp);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                primary.withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$timeStr hs',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          log.memberName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (log.partnerName != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.neonGreen
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Pareja: ${log.partnerName}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.neonGreen,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonGreen
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.neonGreen
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.assignment_turned_in_rounded,
                                            size: 14,
                                            color: AppTheme.neonGreen,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Casos: ${log.detectedCasesCount}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.neonGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.skyBlue
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.skyBlue
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.phone_in_talk_rounded,
                                            size: 14,
                                            color: AppTheme.skyBlue,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Llamados: ${log.callsCount}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.skyBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (log.observations.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    log.observations,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          textPrimary.withValues(alpha: 0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // SECCIÓN: FICHAS DE CASOS (Solo si el evento ya empezó o ya tiene casos)
                  if (isStarted || cases.isNotEmpty) ...[
                    Text(
                      'Fichas de Caso (Reducción de Daños)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.assignment_add),
                              label: const Text('NUEVA FICHA DE CASO'),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                if (widget.onOpenCaseForm != null) {
                                  widget.onOpenCaseForm!(event);
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CaseFormScreen(event: event),
                                    ),
                                  );
                                }
                              },
                            ),
                            if (cases.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.list_alt_rounded, size: 18),
                                label: Text('Ver Casos (${cases.length})'),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EventCasesScreen(event: event),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // SECCIÓN: STAFF ANOTADO SIN CONTENEDOR
                  Text(
                    'Staff Asignado (${staffUsers.length} / ${event.requiredStaffCount})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (staffUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Text(
                        'Aún no hay miembros anotados en este evento.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: staffUsers.length,
                      itemBuilder: (context, index) {
                        final member = staffUsers[index];
                        ImageProvider? avatarImage;
                        if (member.photoUrl != null &&
                            member.photoUrl!.trim().isNotEmpty) {
                          final raw = member.photoUrl!.trim();
                          if (raw.startsWith('http')) {
                            avatarImage = NetworkImage(raw);
                          } else {
                            try {
                              final cleanBase64 = raw.contains(',')
                                  ? raw.split(',').last
                                  : raw;
                              avatarImage =
                                  MemoryImage(base64Decode(cleanBase64));
                            } catch (_) {
                              avatarImage = null;
                            }
                          }
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: surfaceContainer,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? Text(
                                    member.firstName.isNotEmpty
                                        ? member.firstName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            member.fullName,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorarioCol extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;

  const _HorarioCol({
    required this.label,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
