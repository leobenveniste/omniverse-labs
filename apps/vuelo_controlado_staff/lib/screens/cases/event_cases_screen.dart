import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/case_model.dart';
import '../../services/case_service.dart';
import '../../services/drive_sync_service.dart';
import '../../theme/app_theme.dart';
import 'case_form_screen.dart';

class EventCasesScreen extends StatefulWidget {
  final EventModel event;

  const EventCasesScreen({super.key, required this.event});

  @override
  State<EventCasesScreen> createState() => _EventCasesScreenState();
}

class _EventCasesScreenState extends State<EventCasesScreen> {
  String _searchQuery = '';
  bool _isSyncing = false;

  Future<void> _syncToDrive() async {
    final caseService = context.read<CaseService>();
    final cases = caseService.getCasesForEvent(widget.event.id);

    if (cases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay casos para sincronizar.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    final result = await DriveSyncService.syncCasesToDrive(
      event: widget.event,
      cases: cases,
    );

    if (!mounted) return;
    setState(() => _isSyncing = false);

    final messenger = ScaffoldMessenger.of(context);
    if (result.success) {
      await caseService.markCasesAsSynced(widget.event.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseService = context.watch<CaseService>();
    final allCases = caseService.getCasesForEvent(widget.event.id);

    final filteredCases = allCases.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.personName.toLowerCase().contains(query) ||
          c.interventionType.toLowerCase().contains(query) ||
          c.symptoms.toLowerCase().contains(query) ||
          c.substances.any((s) => s.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Casos: ${widget.event.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.neonGreen),
            tooltip: 'Exportar / Compartir CSV',
            onPressed: allCases.isEmpty
                ? null
                : () => DriveSyncService.shareCasesFile(
                      event: widget.event,
                      cases: allCases,
                    ),
          ),
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonGreen,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined,
                    color: AppTheme.neonGreen),
            tooltip: 'Sincronizar a Google Drive',
            onPressed: _isSyncing || allCases.isEmpty ? null : _syncToDrive,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y contador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por persona, síntoma o tipo...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ],
            ),
          ),

          // Resumen rápido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total registrados: ${allCases.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pendientes de Drive: ${caseService.getPendingSyncCount(widget.event.id)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: caseService.getPendingSyncCount(widget.event.id) > 0
                        ? AppTheme.warningOrange
                        : AppTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Listado de casos
          Expanded(
            child: filteredCases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open,
                            size: 54, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron casos con ese criterio.'
                              : 'No hay fichas de casos registradas todavía.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: filteredCases.length,
                    itemBuilder: (context, index) {
                      final c = filteredCases[index];
                      return _CaseCard(caseItem: c);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.neonGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva Ficha',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaseFormScreen(event: widget.event),
            ),
          );
        },
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final CaseModel caseItem;

  const _CaseCard({required this.caseItem});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm \'hs\' (d MMM)');

    return Card(
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
                    const Icon(Icons.access_time,
                        size: 14, color: AppTheme.neonGreen),
                    const SizedBox(width: 6),
                    Text(
                      timeFormat.format(caseItem.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: caseItem.isSyncedToDrive
                        ? AppTheme.neonGreen.withValues(alpha: 0.15)
                        : AppTheme.warningOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    caseItem.isSyncedToDrive ? 'Sincronizado' : 'Solo Local',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: caseItem.isSyncedToDrive
                          ? AppTheme.neonGreen
                          : AppTheme.warningOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              caseItem.interventionType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Persona: ${caseItem.personName} • Edad: ${caseItem.personAge.isEmpty ? "N/E" : caseItem.personAge} • Género: ${caseItem.personGender}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            if (caseItem.substances.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: caseItem.substances.map((s) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textPrimary),
                      children: [
                        const TextSpan(
                          text: 'Síntoma: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonGreen),
                        ),
                        TextSpan(text: caseItem.symptoms),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textPrimary),
                      children: [
                        const TextSpan(
                          text: 'Acción: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonGreen),
                        ),
                        TextSpan(text: caseItem.actionsTaken),
                      ],
                    ),
                  ),
                  if (caseItem.observations.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                        children: [
                          const TextSpan(
                            text: 'Obs: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: caseItem.observations),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Registrado por: ${caseItem.registeredByUserName}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
