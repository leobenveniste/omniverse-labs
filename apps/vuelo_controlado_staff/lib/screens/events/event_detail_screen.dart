import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/case_service.dart';
import '../../services/drive_sync_service.dart';
import '../../theme/app_theme.dart';
import '../cases/case_form_screen.dart';
import '../cases/event_cases_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isSyncing = false;

  Future<void> _handleSyncToDrive() async {
    final eventService = context.read<EventService>();
    final caseService = context.read<CaseService>();
    final event = eventService.getEventById(widget.eventId);
    if (event == null) return;

    final cases = caseService.getCasesForEvent(event.id);
    if (cases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay fichas de casos registradas en este evento.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    final result = await DriveSyncService.syncCasesToDrive(
      event: event,
      cases: cases,
    );

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });

      if (result.success) {
        await caseService.markCasesAsSynced(event.id);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.darkSurface,
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.neonGreen),
                  SizedBox(width: 8),
                  Text('Sincronización Exitosa'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.message,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Podés también guardar o compartir una copia de respaldo inmediatamente:',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Compartir Respaldo'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    DriveSyncService.shareCasesFile(event: event, cases: cases);
                  },
                ),
                ElevatedButton(
                  child: const Text('Entendido'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final eventService = context.watch<EventService>();
    final caseService = context.watch<CaseService>();
    final currentUser = authService.currentUser;

    final event = eventService.getEventById(widget.eventId);
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Evento no encontrado.')),
      );
    }

    final dateFormat = DateFormat('EEEE d \'de\' MMMM \'de\' yyyy', 'es');
    final isStaff = currentUser != null && event.isUserInStaff(currentUser.id);
    final isStarted = event.hasStarted;
    final cases = caseService.getCasesForEvent(event.id);
    final pendingSync = caseService.getPendingSyncCount(event.id);

    // Buscar nombres de miembros sumados
    final allUsers = authService.users;
    final staffUsers = allUsers.where((u) => event.staffIds.contains(u.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
        actions: [
          if (currentUser != null && currentUser.canCreateEvents)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.neonGreen),
              color: AppTheme.darkSurface,
              onSelected: (val) async {
                if (val == 'toggle_start') {
                  await eventService.toggleEventStarted(event.id);
                } else if (val == 'close') {
                  await eventService.closeEvent(event.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_start',
                  child: Row(
                    children: [
                      Icon(
                        event.isManuallyStarted
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        color: AppTheme.neonGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(event.isManuallyStarted
                          ? 'Pausar Inicio Manual'
                          : 'Forzar Inicio de Evento'),
                    ],
                  ),
                ),
                if (!event.isManuallyClosed)
                  const PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(Icons.stop_circle_outlined,
                            color: AppTheme.errorRed, size: 20),
                        SizedBox(width: 10),
                        Text('Cerrar / Finalizar Evento'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Información Principal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isStarted
                                ? AppTheme.neonGreen.withValues(alpha: 0.15)
                                : AppTheme.darkBorder,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isStarted
                                  ? AppTheme.neonGreen
                                  : AppTheme.textSecondary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            event.statusText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isStarted
                                  ? AppTheme.neonGreen
                                  : AppTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (event.location != null && event.location!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.place,
                              size: 16, color: AppTheme.neonGreen),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            size: 16, color: AppTheme.neonGreen),
                        const SizedBox(width: 6),
                        Text(
                          dateFormat.format(event.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _HorarioCol(
                              label: 'Puertas', time: '${event.doorsOpenTime} hs'),
                          _HorarioCol(
                              label: 'Inicio', time: '${event.startTime} hs'),
                          _HorarioCol(
                              label: 'Cierre', time: '${event.endTime} hs'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botón de Sumarse al Staff
            if (currentUser != null)
              if (isStaff)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.neonGreen),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.neonGreen, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Ya estás sumado a este evento!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.neonGreen,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Formás parte activa del equipo de guardia.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await eventService.leaveEvent(
                              event.id, currentUser.id);
                        },
                        child: const Text(
                          'Bajarme',
                          style: TextStyle(color: AppTheme.errorRed),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('SUMARME A ESTE EVENTO'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await eventService.joinEvent(event.id, currentUser.id);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('¡Te sumaste al staff de este evento!'),
                        backgroundColor: AppTheme.neonGreen,
                      ),
                    );
                  },
                ),

            const SizedBox(height: 24),

            // SECCIÓN: FICHAS DE CASOS
            const Text(
              'Fichas de Caso (Reducción de Daños)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            if (isStarted) ...[
              // Banner evento en curso
              Card(
                color: AppTheme.darkSurface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonGreen,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.assignment_add),
                        label: const Text('NUEVA FICHA DE CASO'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CaseFormScreen(event: event),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.list_alt, size: 18),
                              label: Text('Ver Casos (${cases.length})'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventCasesScreen(event: event),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: _isSyncing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.neonGreen,
                                      ),
                                    )
                                  : Badge(
                                      isLabelVisible: pendingSync > 0,
                                      label: Text('$pendingSync'),
                                      backgroundColor: AppTheme.warningOrange,
                                      child: const Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 18),
                                    ),
                              label: const Text('Sincronizar'),
                              onPressed:
                                  _isSyncing ? null : _handleSyncToDrive,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock,
                        color: AppTheme.warningOrange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fichas de caso bloqueadas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Se habilitarán cuando el evento comience (a las ${event.doorsOpenTime} hs o cuando la producción lo inicie).',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // SECCIÓN: STAFF ANOTADO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Staff Asignado (${staffUsers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (staffUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aún no hay miembros anotados en este evento.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: staffUsers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = staffUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.darkCard,
                        child: Text(
                          member.firstName.isNotEmpty
                              ? member.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.neonGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        member.fullName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        member.roles.join(' • '),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: member.isSuperAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.neonGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SUPERADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.neonGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HorarioCol extends StatelessWidget {
  final String label;
  final String time;

  const _HorarioCol({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
