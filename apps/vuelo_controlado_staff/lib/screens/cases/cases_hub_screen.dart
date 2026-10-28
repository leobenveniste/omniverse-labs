import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/case_model.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../services/case_service.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/motion_components.dart';
import 'case_form_screen.dart';

class CasesHubScreen extends StatefulWidget {
  final String? initialEventId;
  final void Function(EventModel event, CaseModel? existingCase)? onOpenCaseForm;

  const CasesHubScreen({
    super.key,
    this.initialEventId,
    this.onOpenCaseForm,
  });

  @override
  State<CasesHubScreen> createState() => _CasesHubScreenState();
}

class _CasesHubScreenState extends State<CasesHubScreen> {
  String? _selectedEventId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
  }

  EventModel? _determineDefaultEvent(List<EventModel> events) {
    if (events.isEmpty) return null;

    // 1. Si ya hay uno seleccionado y existe en la lista, conservarlo
    if (_selectedEventId != null) {
      final match = events.where((e) => e.id == _selectedEventId).toList();
      if (match.isNotEmpty) return match.first;
    }

    // 2. Si hay un evento actual (iniciado o fecha de hoy), seleccionarlo por defecto
    final now = DateTime.now();
    try {
      final active = events.firstWhere(
        (e) =>
            e.hasStarted ||
            (e.date.year == now.year &&
                e.date.month == now.month &&
                e.date.day == now.day),
      );
      return active;
    } catch (_) {}

    // 3. Fallback: el más reciente
    return events.first;
  }

  @override
  Widget build(BuildContext context) {
    final eventService = context.watch<EventService>();
    final caseService = context.watch<CaseService>();
    final authService = context.watch<AuthService>();
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor(context);
    final events = eventService.events;
    final currentUser = authService.currentUser;

    final selectedEvent = _determineDefaultEvent(events);
    if (selectedEvent != null && _selectedEventId != selectedEvent.id) {
      _selectedEventId = selectedEvent.id;
    }

    final allCases = selectedEvent != null
        ? caseService.getCasesForEvent(selectedEvent.id)
        : <CaseModel>[];

    final canAddCases = selectedEvent != null && selectedEvent.hasStarted;

    final filteredCases = allCases.where((c) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c.personName.toLowerCase().contains(q) ||
          c.interventionType.toLowerCase().contains(q) ||
          c.symptoms.toLowerCase().contains(q) ||
          c.substances.any((s) => s.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppHeaderTitle(title: 'Casos'),
        actions: [
          if (canAddCases)
            Tooltip(
              message: 'Nuevo Caso',
              child: FilledButton.icon(
                style: AppTheme.headerActionButtonStyle(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo Caso'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (widget.onOpenCaseForm != null) {
                    widget.onOpenCaseForm!(selectedEvent, null);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CaseFormScreen(event: selectedEvent),
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            children: [
              // Panel de Selección de Evento
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de Evento Dropdown / Picker
                    if (events.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.borderColor(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: AppTheme.warningOrange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay eventos disponibles. Creá un evento primero para registrar casos.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondaryColor(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.borderColor(context),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedEvent?.id,
                            isExpanded: true,
                            icon: Icon(
                              Icons.unfold_more_rounded,
                              color: primary,
                            ),
                            dropdownColor: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            items: events.map((ev) {
                              final isCurrent = ev.hasStarted ||
                                  (ev.date.day == DateTime.now().day &&
                                      ev.date.month == DateTime.now().month &&
                                      ev.date.year == DateTime.now().year);
                              return DropdownMenuItem<String>(
                                value: ev.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      isCurrent
                                          ? Icons.bolt_rounded
                                          : Icons.event_available_rounded,
                                      size: 18,
                                      color: isCurrent
                                          ? primary
                                          : AppTheme.textSecondaryColor(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ev.name,
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 14,
                                          color: AppTheme.textPrimaryColor(context),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'ACTUAL',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId != null) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedEventId = newId);
                              }
                            },
                          ),
                        ),
                      ),

                    // Barra de búsqueda rápida
                    if (allCases.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText:
                              'Buscar por persona, síntoma o sustancia...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  tooltip: 'Limpiar búsqueda',
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Lista de casos
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Text(
                          'Creá un evento para comenzar.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : filteredCases.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.medical_information_outlined,
                                    size: 52,
                                    color: AppTheme.textSecondaryColor(context)
                                        .withValues(alpha: 0.45),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No se encontraron casos que coincidan.'
                                        : 'Aún no hay casos registrados para este evento.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchQuery.isEmpty &&
                                      selectedEvent != null) ...[
                                    if (canAddCases) ...[
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        label: const Text('Registrar Primer Caso'),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          if (widget.onOpenCaseForm != null) {
                                            widget.onOpenCaseForm!(
                                                selectedEvent, null);
                                          } else {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => CaseFormScreen(
                                                    event: selectedEvent),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceContainer(context),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppTheme.borderColor(context),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.lock_clock_outlined,
                                              size: 18,
                                              color: AppTheme.warningOrange,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Fichas habilitadas a las ${selectedEvent.doorsOpenTime.isNotEmpty ? selectedEvent.doorsOpenTime : selectedEvent.startTime} hs',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.textSecondaryColor(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
                            itemCount: filteredCases.length,
                            itemBuilder: (context, index) {
                              final caseItem = filteredCases[index];
                              return StaggeredEntrance(
                                index: index,
                                child: _CaseItemCard(
                                  caseItem: caseItem,
                                  currentUserId: currentUser?.id ?? '',
                                  onEdit: () {
                                    HapticFeedback.selectionClick();
                                    if (widget.onOpenCaseForm != null) {
                                      widget.onOpenCaseForm!(
                                          selectedEvent!, caseItem);
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CaseFormScreen(
                                            event: selectedEvent!,
                                            existingCase: caseItem,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseItemCard extends StatelessWidget {
  final CaseModel caseItem;
  final String currentUserId;
  final VoidCallback onEdit;

  const _CaseItemCard({
    required this.caseItem,
    required this.currentUserId,
    required this.onEdit,
  });

  Color _getInterventionColor(BuildContext context, String type) {
    final lower = type.toLowerCase();
    if (lower.contains('derivación') || lower.contains('intoxicación')) {
      return AppTheme.errorRed;
    }
    if (lower.contains('primeros auxilios') ||
        lower.contains('baja de presión')) {
      return AppTheme.warningOrange;
    }
    if (lower.contains('hidratación')) {
      return AppTheme.cyanAccent;
    }
    return AppTheme.primaryColor(context);
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getInterventionColor(context, caseItem.interventionType);
    final timeStr = DateFormat('HH:mm').format(caseItem.timestamp);

    return PressableScale(
      onTap: onEdit,
      targetScale: 0.98,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          caseItem.resolution.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$timeStr hs',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (caseItem.isComplexCase)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'COMPLEJO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${caseItem.gender} • ${caseItem.ageRange} • ${caseItem.moment} (${caseItem.duration})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              if (caseItem.symptoms.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  caseItem.symptoms,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
              if (caseItem.substances.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: caseItem.substanceEntries.entries.map((entry) {
                    final label = entry.value.isNotEmpty
                        ? '${entry.key} (${entry.value})'
                        : entry.key;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor(context)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
