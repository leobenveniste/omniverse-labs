import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/case_model.dart';
import '../../services/case_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_background.dart';
import 'case_form_screen.dart';

class EventCasesScreen extends StatefulWidget {
  final EventModel event;

  const EventCasesScreen({super.key, required this.event});

  @override
  State<EventCasesScreen> createState() => _EventCasesScreenState();
}

class _EventCasesScreenState extends State<EventCasesScreen> {
  String _searchQuery = '';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            style: AppTheme.headerIconButtonStyle(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            tooltip: 'Volver',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: AppHeaderTitle(title: 'Casos: ${widget.event.name}'),
        actions: [
          Tooltip(
            message: 'Nueva Ficha de Caso',
            child: FilledButton.icon(
              style: AppTheme.headerActionButtonStyle(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva Ficha'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaseFormScreen(event: widget.event),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              children: [
                // Barra de búsqueda y contador
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por persona, síntoma o tipo...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              tooltip: 'Limpiar búsqueda',
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // Resumen rápido
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total registrados: ${allCases.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Listado de casos
                Expanded(
                  child: filteredCases.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open_rounded,
                                  size: 52,
                                  color: AppTheme.textSecondaryColor(context)
                                      .withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No se encontraron casos con ese criterio.'
                                      : 'No hay fichas de casos registradas todavía.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: filteredCases.length,
                          itemBuilder: (context, index) {
                            final c = filteredCases[index];
                            return _CaseCard(
                              caseItem: c,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CaseFormScreen(
                                      event: widget.event,
                                      existingCase: c,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final CaseModel caseItem;
  final VoidCallback onTap;

  const _CaseCard({
    required this.caseItem,
    required this.onTap,
  });

  String _formatCaseTime(DateTime time) {
    try {
      return DateFormat('HH:mm \'hs\' (d MMM)', 'es').format(time);
    } catch (_) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute hs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
                      Icon(Icons.access_time_rounded,
                          size: 14, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        _formatCaseTime(caseItem.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                caseItem.interventionType,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Persona: ${caseItem.personName.isEmpty ? "Anónimo" : caseItem.personName} • Edad: ${caseItem.personAge.isEmpty ? "N/E" : caseItem.personAge} • Género: ${caseItem.personGender}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              if (caseItem.substances.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: caseItem.substances.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor(context)),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: textPrimary),
                        children: [
                          TextSpan(
                            text: 'Síntoma: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: primary),
                          ),
                          TextSpan(text: caseItem.symptoms),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: textPrimary),
                        children: [
                          TextSpan(
                            text: 'Acción: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: primary),
                          ),
                          TextSpan(text: caseItem.actionsTaken),
                        ],
                      ),
                    ),
                    if (caseItem.observations.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          children: [
                            const TextSpan(
                              text: 'Obs: ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: caseItem.observations),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Registrado por: ${caseItem.registeredByUserName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
