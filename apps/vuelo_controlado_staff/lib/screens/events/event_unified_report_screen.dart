import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/event_unified_report.dart';
import '../../services/auth_service.dart';
import '../../services/case_service.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_header.dart';
import '../../widgets/motion_components.dart';

class EventUnifiedReportScreen extends StatefulWidget {
  final EventModel event;

  const EventUnifiedReportScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventUnifiedReportScreen> createState() =>
      _EventUnifiedReportScreenState();
}

class _EventUnifiedReportScreenState extends State<EventUnifiedReportScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _durationController;
  late final TextEditingController _producerController;
  late final TextEditingController _otherEventTypeController;
  late final TextEditingController _otherTimeSlotController;
  late final TextEditingController _otherDayNumberController;
  late final TextEditingController _medicalAttendedController;
  late final TextEditingController _medicalTransferredController;
  late final TextEditingController _vcAttendedController;

  // Composición servicio médico
  late final TextEditingController _compTraumaController;
  late final TextEditingController _compIntoxController;
  late final TextEditingController _compCrisisController;
  late final TextEditingController _compMalestarController;
  late final TextEditingController _compOther1NameController;
  late final TextEditingController _compOther1CountController;
  late final TextEditingController _compOther2NameController;
  late final TextEditingController _compOther2CountController;

  // Vuelo Controlado
  late final TextEditingController _vueloVolunteersController;
  late final TextEditingController _vueloFruitController;
  late final TextEditingController _otherInfoController;

  // Estados seleccionables
  bool _vueloPresent = true;
  String _eventType = 'Festival';
  String _timeSlot = 'Nocturno';
  String _spaceType = 'Outdoor';
  String _dayNumber = 'Única';
  bool _hasFreeWater = true;
  String _perceivedDensity = 'Media';
  final Set<String> _selectedWeather = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rep = widget.event.unifiedReport;

    _durationController =
        TextEditingController(text: rep?.durationTotal ?? '');
    _producerController = TextEditingController(text: rep?.producer ?? '');
    _otherEventTypeController =
        TextEditingController(text: rep?.otherEventType ?? '');
    _otherTimeSlotController =
        TextEditingController(text: rep?.otherTimeSlot ?? '');
    _otherDayNumberController =
        TextEditingController(text: rep?.otherDayNumber ?? '');

    _medicalAttendedController = TextEditingController(
      text: rep != null ? rep.medicalAttendedCount.toString() : '0',
    );
    _medicalTransferredController = TextEditingController(
      text: rep != null ? rep.medicalTransferredCount.toString() : '0',
    );

    // Calcular o precargar casos de Vuelo Controlado
    final initialVc = rep?.vcAttendedCount ?? 0;
    _vcAttendedController = TextEditingController(
      text: initialVc > 0 ? initialVc.toString() : '',
    );

    // Composición
    final comp = rep?.medicalComposition ?? {};
    _compTraumaController =
        TextEditingController(text: (comp['traumatologico'] ?? 0).toString());
    _compIntoxController =
        TextEditingController(text: (comp['intoxicacion'] ?? 0).toString());
    _compCrisisController = TextEditingController(
        text: (comp['crisisPsicologica'] ?? 0).toString());
    _compMalestarController =
        TextEditingController(text: (comp['malestarFisico'] ?? 0).toString());
    _compOther1NameController =
        TextEditingController(text: rep?.medicalOther1Name ?? '');
    _compOther1CountController = TextEditingController(
        text: rep?.medicalOther1Count?.toString() ?? '0');
    _compOther2NameController =
        TextEditingController(text: rep?.medicalOther2Name ?? '');
    _compOther2CountController = TextEditingController(
        text: rep?.medicalOther2Count?.toString() ?? '0');

    // VC específicos
    _vueloVolunteersController = TextEditingController(
      text: rep?.vueloVolunteersCount ??
          (widget.event.currentStaffCount > 0
              ? widget.event.currentStaffCount.toString()
              : ''),
    );
    _vueloFruitController =
        TextEditingController(text: rep?.vueloFruitQuantity ?? '');
    _otherInfoController =
        TextEditingController(text: rep?.otherRelevantInfo ?? '');

    if (rep != null) {
      _vueloPresent = rep.vueloPresent;
      _eventType = rep.eventType;
      _timeSlot = rep.timeSlot;
      _spaceType = rep.spaceType;
      _dayNumber = rep.dayNumber;
      _hasFreeWater = rep.hasFreeWater;
      _perceivedDensity = rep.perceivedDensity;
      _selectedWeather.addAll(rep.weatherTypes);
    } else {
      _selectedWeather.add('Templado');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si no tiene valor aún en casos atendidos por VC, pre-llenar con el conteo de la app
    if (_vcAttendedController.text.isEmpty) {
      final caseService = context.read<CaseService>();
      final count = caseService.getCasesForEvent(widget.event.id).length;
      _vcAttendedController.text = count.toString();
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _producerController.dispose();
    _otherEventTypeController.dispose();
    _otherTimeSlotController.dispose();
    _otherDayNumberController.dispose();
    _medicalAttendedController.dispose();
    _medicalTransferredController.dispose();
    _vcAttendedController.dispose();
    _compTraumaController.dispose();
    _compIntoxController.dispose();
    _compCrisisController.dispose();
    _compMalestarController.dispose();
    _compOther1NameController.dispose();
    _compOther1CountController.dispose();
    _compOther2NameController.dispose();
    _compOther2CountController.dispose();
    _vueloVolunteersController.dispose();
    _vueloFruitController.dispose();
    _otherInfoController.dispose();
    super.dispose();
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, revisa los campos requeridos.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final eventService = context.read<EventService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    final comp = <String, int>{
      'traumatologico': int.tryParse(_compTraumaController.text.trim()) ?? 0,
      'intoxicacion': int.tryParse(_compIntoxController.text.trim()) ?? 0,
      'crisisPsicologica': int.tryParse(_compCrisisController.text.trim()) ?? 0,
      'malestarFisico': int.tryParse(_compMalestarController.text.trim()) ?? 0,
    };

    final report = EventUnifiedReport(
      durationTotal: _durationController.text.trim(),
      producer: _producerController.text.trim(),
      vueloPresent: _vueloPresent,
      eventType: _eventType,
      otherEventType: _eventType == 'Otro'
          ? _otherEventTypeController.text.trim()
          : null,
      timeSlot: _timeSlot,
      otherTimeSlot: _timeSlot == 'Extendido'
          ? _otherTimeSlotController.text.trim()
          : null,
      spaceType: _spaceType,
      dayNumber: _dayNumber,
      otherDayNumber: _dayNumber == 'Otro'
          ? _otherDayNumberController.text.trim()
          : null,
      hasFreeWater: _hasFreeWater,
      perceivedDensity: _perceivedDensity,
      weatherTypes: _selectedWeather.toList(),
      medicalAttendedCount:
          int.tryParse(_medicalAttendedController.text.trim()) ?? 0,
      medicalTransferredCount:
          int.tryParse(_medicalTransferredController.text.trim()) ?? 0,
      vcAttendedCount: int.tryParse(_vcAttendedController.text.trim()) ?? 0,
      medicalComposition: comp,
      medicalOther1Name: _compOther1NameController.text.trim().isNotEmpty
          ? _compOther1NameController.text.trim()
          : null,
      medicalOther1Count:
          int.tryParse(_compOther1CountController.text.trim()),
      medicalOther2Name: _compOther2NameController.text.trim().isNotEmpty
          ? _compOther2NameController.text.trim()
          : null,
      medicalOther2Count:
          int.tryParse(_compOther2CountController.text.trim()),
      vueloVolunteersCount: _vueloVolunteersController.text.trim(),
      vueloFruitQuantity: _vueloFruitController.text.trim(),
      otherRelevantInfo: _otherInfoController.text.trim(),
      completedByUserId: currentUser.id,
      completedByUserName: currentUser.fullName,
      completedAt: DateTime.now(),
    );

    final success = await eventService.saveEventReport(
      eventId: widget.event.id,
      report: report,
      currentUser: currentUser,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro unificado por evento guardado con éxito.'),
          backgroundColor: AppTheme.emeraldDark,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos de Producción para guardar este informe.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primaryColor(context);
    final dateStr = DateFormat('dd/MM/yyyy').format(widget.event.date);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const AppHeaderTitle(title: 'Registro por Evento'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressableScale(
              onTap: _isSaving ? null : _saveReport,
              child: FilledButton.icon(
                style: AppTheme.headerActionButtonStyle(context),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Guardar'),
                onPressed: _isSaving ? null : _saveReport,
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              // Encabezado institucional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'REGISTRO UNIFICADO POR EVENTO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.event.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.location} • $dateStr',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sección 1: Datos de Producción & Evento
              _buildSectionCard(
                title: '1. Datos de Producción y Evento',
                icon: Icons.business_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Duración total',
                            hintText: 'Ej: 8 horas, 12h',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _producerController,
                          decoration: const InputDecoration(
                            labelText: 'Productora',
                            hintText: 'Nombre de productora',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Presencia de Vuelo
                  _buildLabel('Presencia de Vuelo Controlado*'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChoiceChip(
                        label: 'Si',
                        isSelected: _vueloPresent,
                        onSelected: () => setState(() => _vueloPresent = true),
                      ),
                      const SizedBox(width: 8),
                      _buildChoiceChip(
                        label: 'No',
                        isSelected: !_vueloPresent,
                        onSelected: () => setState(() => _vueloPresent = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tipo de evento
                  _buildLabel('Tipo de evento'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Festival', 'Boliche', 'Fecha única', 'Otro']
                        .map((type) => _buildChoiceChip(
                              label: type,
                              isSelected: _eventType == type,
                              onSelected: () => setState(() => _eventType = type),
                            ))
                        .toList(),
                  ),
                  if (_eventType == 'Otro') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _otherEventTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Especificar otro tipo de evento',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Franja temporal
                  _buildLabel('Franja temporal'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Diurno', 'Sunset', 'Nocturno', 'Extendido']
                        .map((slot) => _buildChoiceChip(
                              label: slot,
                              isSelected: _timeSlot == slot,
                              onSelected: () => setState(() => _timeSlot = slot),
                            ))
                        .toList(),
                  ),
                  if (_timeSlot == 'Extendido') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _otherTimeSlotController,
                      decoration: const InputDecoration(
                        labelText: 'Detalle de horario extendido',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Tipo de espacio & Jornada
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Espacio'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['Indoor', 'Outdoor']
                                  .map((s) => _buildChoiceChip(
                                        label: s,
                                        isSelected: _spaceType == s,
                                        onSelected: () =>
                                            setState(() => _spaceType = s),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Agua gratuita'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildChoiceChip(
                                  label: 'Si',
                                  isSelected: _hasFreeWater,
                                  onSelected: () =>
                                      setState(() => _hasFreeWater = true),
                                ),
                                const SizedBox(width: 8),
                                _buildChoiceChip(
                                  label: 'No',
                                  isSelected: !_hasFreeWater,
                                  onSelected: () =>
                                      setState(() => _hasFreeWater = false),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Jornada
                  _buildLabel('Jornada'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Única', 'Día 1', 'Día 2', 'Día 3', 'Otro']
                        .map((d) => _buildChoiceChip(
                              label: d,
                              isSelected: _dayNumber == d,
                              onSelected: () => setState(() => _dayNumber = d),
                            ))
                        .toList(),
                  ),
                  if (_dayNumber == 'Otro') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _otherDayNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Especificar jornada',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Densidad percibida
                  _buildLabel('Densidad percibida'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Baja', 'Media', 'Alta']
                        .map((den) => _buildChoiceChip(
                              label: den,
                              isSelected: _perceivedDensity == den,
                              onSelected: () =>
                                  setState(() => _perceivedDensity = den),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Tipo de clima (múltiple)
                  _buildLabel('Tipo de clima (selección múltiple)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Calor', 'Frío', 'Templado', 'Húmedo', 'Lluvia']
                        .map((w) {
                      final selected = _selectedWeather.contains(w);
                      return _buildChoiceChip(
                        label: w,
                        isSelected: selected,
                        onSelected: () {
                          setState(() {
                            if (selected) {
                              _selectedWeather.remove(w);
                            } else {
                              _selectedWeather.add(w);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sección 2: Totales de Casos Atendidos
              _buildSectionCard(
                title: '2. Totales de Casos Atendidos',
                icon: Icons.medical_services_outlined,
                children: [
                  TextFormField(
                    controller: _medicalAttendedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText:
                          'Casos atendidos por el servicio médico / ambulancia',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _medicalTransferredController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Casos trasladados / derivados',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vcAttendedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Casos atendidos por Vuelo Controlado (VC)*',
                      hintText: '0',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sección 3: Composición de Atenciones Servicio Médico
              _buildSectionCard(
                title: '3. Composición Servicio Médico',
                icon: Icons.pie_chart_outline_rounded,
                children: [
                  Text(
                    'Frecuencia (f) y porcentaje aproximado según servicio médico:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCompositionRow(
                    label: 'Traumatológico',
                    controller: _compTraumaController,
                  ),
                  const SizedBox(height: 8),
                  _buildCompositionRow(
                    label: 'Intoxicación / consumo',
                    controller: _compIntoxController,
                  ),
                  const SizedBox(height: 8),
                  _buildCompositionRow(
                    label: 'Crisis psicológica / conductual',
                    controller: _compCrisisController,
                  ),
                  const SizedBox(height: 8),
                  _buildCompositionRow(
                    label: 'Malestar físico agudo / desregulación',
                    controller: _compMalestarController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _compOther1NameController,
                          decoration: const InputDecoration(
                            labelText: 'Otro motivo 1',
                            hintText: 'Nombre de afección',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _compOther1CountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'f',
                            hintText: '0',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _compOther2NameController,
                          decoration: const InputDecoration(
                            labelText: 'Otro motivo 2',
                            hintText: 'Nombre de afección',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _compOther2CountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'f',
                            hintText: '0',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sección 4: Vuelo Controlado (Voluntarios y Recursos)
              _buildSectionCard(
                title: '4. Datos de Vuelo Controlado',
                icon: Icons.shield_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _vueloVolunteersController,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad de Vuelos',
                            hintText: 'Ej: 14',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _vueloFruitController,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad de Fruta',
                            hintText: 'Ej: 15 kg, 2 cajones',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherInfoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Otra info relevante',
                      hintText: 'Observaciones generales del operativo...',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryColor(context),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final cardBg = AppTheme.cardColor(context);
    final borderCol = AppTheme.borderColor(context);
    final primary = AppTheme.primaryColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final primary = AppTheme.primaryColor(context);
    final isDark = AppTheme.isDark(context);

    return PressableScale(
      onTap: onSelected,
      targetScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.24 : 0.14)
              : (isDark
                  ? const Color(0xFF242424)
                  : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : AppTheme.emeraldDark)
                : AppTheme.textSecondaryColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCompositionRow({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimaryColor(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              hintText: '0',
            ),
          ),
        ),
      ],
    );
  }
}
