import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/event_banner_image.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class EventsListScreen extends StatefulWidget {
  final ValueChanged<String>? onSelectEvent;

  const EventsListScreen({super.key, this.onSelectEvent});

  static String formatEventDate(DateTime date) {
    try {
      final formatter = DateFormat('EEEE d \'de\' MMMM', 'es');
      final formatted = formatter.format(date);
      if (formatted.isNotEmpty) {
        return formatted[0].toUpperCase() + formatted.substring(1);
      }
      return formatted;
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  // Filtros de tiempo: por defecto solo está activo próximos eventos.
  bool _filterUpcoming = true;
  bool _filterPast = false;
  String? _selectedRegion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedRegion == null) {
      final user = context.read<AuthService>().currentUser;
      _selectedRegion = (user != null && user.region.isNotEmpty)
          ? user.region
          : AppRegions.buenosAires;
    }
  }

  bool _isPastEvent(EventModel event) => event.isPast;

  bool _isCurrentEvent(EventModel event) => event.isOngoing;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final eventService = context.watch<EventService>();
    final currentUser = authService.currentUser;
    final allEvents = eventService.events;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final currentRegion = _selectedRegion ??
        (currentUser != null && currentUser.region.isNotEmpty
            ? currentUser.region
            : AppRegions.buenosAires);

    // Filtrar primero por región seleccionada
    final regionEvents = allEvents.where((e) {
      if (currentRegion == AppRegions.allRegions) return true;
      return e.region == currentRegion;
    }).toList();

    // Solo roles de admin y organización pueden crear nuevos eventos desde el header
    final canCreateEvent = currentUser != null &&
        (currentUser.isSuperAdmin ||
            currentUser.hasRole(AppRoles.organizacion));

    // Evento actual destacado dentro de la región seleccionada
    EventModel? currentEvent;
    try {
      currentEvent = regionEvents.firstWhere((e) => _isCurrentEvent(e));
    } catch (_) {
      currentEvent = null;
    }

    // Filtrar lista según los filtros activos:
    // Si están ambos o ninguno prendido se muestran todos
    final bool showAll =
        (_filterUpcoming && _filterPast) || (!_filterUpcoming && !_filterPast);

    final filteredEvents = regionEvents.where((e) {
      if (showAll) return true;
      if (_filterUpcoming) return !_isPastEvent(e);
      if (_filterPast) return _isPastEvent(e);
      return true;
    }).toList();

    // Excluir el evento actual destacado de la lista general para no duplicar la tarjeta
    final listEvents = filteredEvents
        .where((e) => currentEvent == null || e.id != currentEvent.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppHeaderTitle(title: 'Eventos'),
        actions: [
          if (canCreateEvent)
            Tooltip(
              message: 'Crear Nuevo Evento',
              child: FilledButton.icon(
                style: AppTheme.headerActionButtonStyle(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateEventScreen(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: CustomScrollView(
            slivers: [
              // Barra de filtros por región y tiempo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // 1. Selector de Región
                            Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: currentRegion,
                                  icon: Icon(Icons.arrow_drop_down_rounded, color: primary),
                                  dropdownColor: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: AppRegions.allRegions,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.public, size: 15),
                                          SizedBox(width: 6),
                                          Text(AppRegions.allRegions),
                                        ],
                                      ),
                                    ),
                                    ...AppRegions.all.map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.place_outlined, size: 15),
                                              SizedBox(width: 6),
                                              Text(r),
                                            ],
                                          ),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedRegion = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. Chip Próximos
                            _buildFilterChip(
                              label: 'Próximos',
                              isSelected: _filterUpcoming,
                              icon: Icons.upcoming_outlined,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _filterUpcoming = !_filterUpcoming);
                              },
                            ),
                            const SizedBox(width: 8),

                            // 3. Chip Pasados
                            _buildFilterChip(
                              label: 'Pasados',
                              isSelected: _filterPast,
                              icon: Icons.history_rounded,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _filterPast = !_filterPast);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tarjeta de Evento Actual (si existe)
                      if (currentEvent != null) ...[
                        _CurrentEventHeroCard(
                          event: currentEvent,
                          currentUserId: currentUser?.id ?? '',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (widget.onSelectEvent != null) {
                              widget.onSelectEvent!(currentEvent!.id);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(
                                    eventId: currentEvent!.id,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // Lista de Eventos Filtrados
              if (filteredEvents.isEmpty && currentEvent == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 56,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (_filterPast && !_filterUpcoming)
                                ? 'No hay eventos pasados registrados en $currentRegion.'
                                : 'No hay próximos eventos en $currentRegion.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (currentRegion != AppRegions.allRegions) ...[
                            const SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.public_rounded, size: 18),
                              label: const Text('Explorar todas las regiones'),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedRegion = AppRegions.allRegions);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else if (listEvents.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.paddingOf(context).bottom + 96,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = listEvents[index];
                        return _EventCard(
                          event: event,
                          currentUserId: currentUser?.id ?? '',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (widget.onSelectEvent != null) {
                              widget.onSelectEvent!(event.id);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EventDetailScreen(eventId: event.id),
                                ),
                              );
                            }
                          },
                        );
                      },
                      childCount: listEvents.length,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 96,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      selectedColor: primary.withValues(alpha: 0.16),
      backgroundColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: isSelected
            ? primary
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        width: isSelected ? 1.5 : 1.0,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _CurrentEventHeroCard extends StatelessWidget {
  final EventModel event;
  final String currentUserId;
  final VoidCallback onTap;

  const _CurrentEventHeroCard({
    required this.event,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final textSecondary = AppTheme.textSecondaryColor(context);
    final hasImage =
        event.imageUrl != null && event.imageUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.18),
            theme.colorScheme.surface,
          ],
        ),
        border: Border.all(
          color: primary.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                EventBannerImage(
                  imageSource: event.imageUrl,
                  height: 144,
                  width: double.infinity,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(23)),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: AppTheme.onPrimaryColor(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'EVENTO ACTUAL / EN CURSO',
                                style: TextStyle(
                                  color: AppTheme.onPrimaryColor(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place_outlined, size: 14, color: primary),
                              const SizedBox(width: 4),
                              Text(
                                event.region,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE d MMMM, y', 'es_AR')
                              .format(event.date)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (event.address != null &&
                                    event.address!.trim().isNotEmpty)
                                ? '${event.location} • ${event.address}'
                                : event.location,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Inicio: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              '${event.startTime} hs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Cierre: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              '${event.endTime} hs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            text: event.requiredStaffCount > 0
                                ? '${event.confirmedStaffCount} / ${event.requiredStaffCount}'
                                : '${event.confirmedStaffCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            children: [
                              if (event.confirmedStaffCount > 0 && event.pendingStaffCount > 0)
                                TextSpan(
                                  text: ' (+${event.pendingStaffCount} pendientes)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFFB300),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: event.quotaProgress,
                              minHeight: 6,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final String currentUserId;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final textSecondary = AppTheme.textSecondaryColor(context);
    final dateString = EventsListScreen.formatEventDate(event.date);
    final hasImage =
        event.imageUrl != null && event.imageUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                EventBannerImage(
                  imageSource: event.imageUrl,
                  height: 136,
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
                              color: AppTheme.textPrimaryColor(context),
                            ),
                          ),
                        ),
                        if (event.hasStarted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ACTIVO',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place_outlined, size: 12, color: primary),
                              const SizedBox(width: 4),
                              Text(
                                event.region,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateString,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Inicio: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              '${event.startTime} hs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Cierre: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              '${event.endTime} hs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (event.address != null &&
                                    event.address!.trim().isNotEmpty)
                                ? '${event.location} • ${event.address}'
                                : event.location,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            text: event.requiredStaffCount > 0
                                ? '${event.confirmedStaffCount} / ${event.requiredStaffCount}'
                                : '${event.confirmedStaffCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            children: [
                              if (event.confirmedStaffCount > 0 && event.pendingStaffCount > 0)
                                TextSpan(
                                  text: ' (+${event.pendingStaffCount} pendientes)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFFB300),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: event.quotaProgress,
                              minHeight: 6,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
