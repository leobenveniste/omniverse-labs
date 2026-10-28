import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/case_model.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../services/case_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_header.dart';
import '../../widgets/motion_components.dart';

class CaseFormScreen extends StatefulWidget {
  final EventModel event;
  final CaseModel? existingCase;
  final VoidCallback? onBack;

  const CaseFormScreen({
    super.key,
    required this.event,
    this.existingCase,
    this.onBack,
  });

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. Perfil & Contexto
  String _gender = 'M';
  String _ageRange = '18 – 25';
  String _moment = 'Main';
  String _duration = 'hasta 30\'';
  String _arrivalMode = 'Solx';
  late final TextEditingController _accompaniedByController;

  // 2. Consumo de Sustancias
  String _consumedSubstances = 'Si';
  final Map<String, String> _substanceQuantities = {};
  late final TextEditingController _mdmaPillNameController;
  late final TextEditingController _otherSubstanceNameController;
  late final TextEditingController _otherSubstanceQuantityController;
  String _isFirstTimeConsuming = 'No';
  String _hasUnderlyingCondition = 'No'; // 'No', 'Desconocido', 'Si'
  late final TextEditingController _underlyingConditionDetailController;

  // 3. Signos Físicos
  final Set<String> _physicalSymptoms = {};
  late final TextEditingController _otherPhysicalSymptomsController;

  // 4. Signos Psicológicos / Emocionales
  final Set<String> _psychologicalSymptoms = {};

  // 5. Cierre & Derivación
  bool _healthTeamIntervened = false;
  bool _isComplexCase = false;
  String _resolution = 'Recuperación íntegra';
  late final TextEditingController _otherResolutionController;
  late final TextEditingController _attendingStaffController;
  late final TextEditingController _relevantInfoController;

  bool _isSaving = false;

  static const List<String> _genderOptions = ['M', 'F', 'No binario'];
  static const List<String> _ageOptions = [
    '-18',
    '18 – 25',
    '26 – 35',
    '36 – 45',
    '+45'
  ];
  static const List<String> _momentOptions = ['Inicio', 'Main', 'Final'];
  static const List<String> _durationOptions = [
    '5\'',
    'hasta 30\'',
    'hasta 1h',
    'más de 1h'
  ];
  static const List<String> _arrivalOptions = [
    'Solx',
    'Traído por amigxs',
    'Detectado en ronda',
    'Acompañadx'
  ];
  static const List<String> _consumedOptions = [
    'Si',
    'No',
    'No sabe si consumió',
    'Desconocido'
  ];

  static const List<String> _officialSubstances = [
    'MDMA Cristal',
    'MDMA Pastilla',
    'Cannabis',
    'Cocaína',
    'LSD',
    'Psilocibina',
    'Alcohol',
    'Tusi',
    'Ketamina',
    'Popper',
    'Tabaco',
    'Medicación',
  ];

  static const List<String> _officialPhysicalSymptoms = [
    'Sensación de calor',
    'Mareos/aturdimiento',
    'Sudoración',
    'Sensación de frío',
    'Midriasis (pupilas dilatadas)',
    'Palidez',
    'Bruxismo (tensión mandibular)',
    'Somnolencia/adormecimiento',
    'Palpitaciones',
    'Debilidad/agotamiento físico',
    'Nauseas',
    'Desmayo',
    'Vómitos',
    'Sensación de desmayo',
    'Dolor de cabeza',
    'Cansancio (quiere descansar)',
  ];

  static const List<String> _officialPsychologicalSymptoms = [
    'Inquietud / Agitación',
    'Confusión / Desorientación',
    'Ansiedad / Angustia / Miedo',
    'Dificultad para seguir consignas',
    'Llanto / Desborde emocional',
    'Desconexión del entorno',
    'Suspicacia / Ideas de persecución',
    'Sensación de irrealidad / extrañeza',
    'Irritabilidad / Hostilidad',
    'Conducta desorganizada',
    'Necesita compañía',
    'Locuacidad (ganas de hablar)',
  ];

  static const List<String> _resolutionOptions = [
    'Recuperación íntegra',
    'Deriva al servicio sanitario',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existingCase;

    _accompaniedByController =
        TextEditingController(text: c?.accompaniedBy ?? '');
    _mdmaPillNameController =
        TextEditingController(text: c?.mdmaPillName ?? '');
    _otherSubstanceNameController =
        TextEditingController(text: c?.otherSubstanceName ?? '');
    _otherSubstanceQuantityController = TextEditingController(
      text: c != null && c.otherSubstanceName != null
          ? c.substanceEntries[c.otherSubstanceName] ?? ''
          : '',
    );
    _underlyingConditionDetailController = TextEditingController(
      text: c != null && c.underlyingCondition.startsWith('Si: ')
          ? c.underlyingCondition.substring(4)
          : '',
    );
    _otherPhysicalSymptomsController =
        TextEditingController(text: c?.otherPhysicalSymptoms ?? '');
    _otherResolutionController =
        TextEditingController(text: c?.otherResolution ?? '');
    _attendingStaffController = TextEditingController(
      text: c?.attendingStaff ?? '',
    );
    _relevantInfoController =
        TextEditingController(text: c?.relevantInfo ?? '');

    if (c != null) {
      _gender = c.gender;
      _ageRange = c.ageRange;
      _moment = c.moment;
      _duration = c.duration;
      _arrivalMode = c.arrivalMode;
      _consumedSubstances = c.consumedSubstances;
      _substanceQuantities.addAll(c.substanceEntries);
      _isFirstTimeConsuming = c.isFirstTimeConsuming;
      if (c.underlyingCondition.startsWith('Si')) {
        _hasUnderlyingCondition = 'Si';
      } else {
        _hasUnderlyingCondition = c.underlyingCondition;
      }
      _physicalSymptoms.addAll(c.physicalSymptoms);
      _psychologicalSymptoms.addAll(c.psychologicalSymptoms);
      _healthTeamIntervened = c.healthTeamIntervened;
      _isComplexCase = c.isComplexCase;
      _resolution = c.resolution;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attendingStaffController.text.isEmpty) {
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        _attendingStaffController.text = currentUser.fullName;
      }
    }
  }

  @override
  void dispose() {
    _accompaniedByController.dispose();
    _mdmaPillNameController.dispose();
    _otherSubstanceNameController.dispose();
    _otherSubstanceQuantityController.dispose();
    _underlyingConditionDetailController.dispose();
    _otherPhysicalSymptomsController.dispose();
    _otherResolutionController.dispose();
    _attendingStaffController.dispose();
    _relevantInfoController.dispose();
    super.dispose();
  }

  void _handleBack() {
    HapticFeedback.selectionClick();
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final authService = context.read<AuthService>();
    final caseService = context.read<CaseService>();
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    // Construir mapa de sustancias finales
    final Map<String, String> finalSubstances = {};
    if (_consumedSubstances == 'Si') {
      _substanceQuantities.forEach((sub, qty) {
        finalSubstances[sub] = qty;
      });
      final otherName = _otherSubstanceNameController.text.trim();
      final otherQty = _otherSubstanceQuantityController.text.trim();
      if (otherName.isNotEmpty) {
        finalSubstances[otherName] = otherQty;
      }
    }

    String finalUnderlying = _hasUnderlyingCondition;
    if (_hasUnderlyingCondition == 'Si') {
      final detail = _underlyingConditionDetailController.text.trim();
      finalUnderlying = detail.isNotEmpty ? 'Si: $detail' : 'Si';
    }

    final newCase = CaseModel(
      id: widget.existingCase?.id ?? '',
      eventId: widget.event.id,
      eventName: widget.event.name,
      registeredByUserId:
          widget.existingCase?.registeredByUserId ?? currentUser.id,
      registeredByUserName:
          widget.existingCase?.registeredByUserName ?? currentUser.fullName,
      timestamp: widget.existingCase?.timestamp ?? DateTime.now(),
      gender: _gender,
      ageRange: _ageRange,
      moment: _moment,
      duration: _duration,
      arrivalMode: _arrivalMode,
      accompaniedBy: _arrivalMode == 'Acompañadx'
          ? _accompaniedByController.text.trim()
          : null,
      consumedSubstances: _consumedSubstances,
      substanceEntries: finalSubstances,
      mdmaPillName: _mdmaPillNameController.text.trim().isNotEmpty
          ? _mdmaPillNameController.text.trim()
          : null,
      otherSubstanceName:
          _otherSubstanceNameController.text.trim().isNotEmpty
              ? _otherSubstanceNameController.text.trim()
              : null,
      isFirstTimeConsuming: _isFirstTimeConsuming,
      underlyingCondition: finalUnderlying,
      physicalSymptoms: _physicalSymptoms.toList(),
      otherPhysicalSymptoms:
          _otherPhysicalSymptomsController.text.trim().isNotEmpty
              ? _otherPhysicalSymptomsController.text.trim()
              : null,
      psychologicalSymptoms: _psychologicalSymptoms.toList(),
      healthTeamIntervened: _healthTeamIntervened,
      isComplexCase: _isComplexCase,
      resolution: _resolution,
      otherResolution: _resolution == 'Otro'
          ? _otherResolutionController.text.trim()
          : null,
      attendingStaff: _attendingStaffController.text.trim().isNotEmpty
          ? _attendingStaffController.text.trim()
          : currentUser.fullName,
      relevantInfo: _relevantInfoController.text.trim(),
    );

    bool success;
    if (widget.existingCase != null) {
      success = await caseService.updateCase(newCase);
    } else {
      success = await caseService.createCase(
        eventId: newCase.eventId,
        eventName: newCase.eventName,
        personName: newCase.personName,
        personAge: newCase.personAge,
        personGender: newCase.personGender,
        interventionType: newCase.interventionType,
        substances: newCase.substances,
        symptoms: newCase.symptoms,
        actionsTaken: newCase.actionsTaken,
        observations: newCase.observations,
        currentUser: currentUser,
        caseModelOverride: newCase,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingCase != null
              ? '✓ Ficha de caso actualizada'
              : '✓ Ficha de atención registrada con éxito'),
          backgroundColor: AppTheme.emeraldDark,
        ),
      );
      _handleBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar la ficha de atención.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primaryColor(context);

    return Scaffold(
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
        title: AppHeaderTitle(
          title: widget.existingCase != null
              ? 'Editar Atención'
              : 'Registro de Atención',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressableScale(
              onTap: _isSaving ? null : _saveCase,
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
                    : const Icon(Icons.check_rounded, size: 18),
                label: const Text('Guardar'),
                onPressed: _isSaving ? null : _saveCase,
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
              // Header institucional
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
                        Icon(Icons.volunteer_activism_outlined,
                            color: primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'REGISTRO UNIFICADO DE ATENCIONES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.event.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Perfil & Contexto
              _buildSectionCard(
                title: '1. Perfil y Contexto de la Persona',
                icon: Icons.person_outline_rounded,
                children: [
                  _buildLabel('Género'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genderOptions
                        .map((g) => _buildChoiceChip(
                              label: g,
                              isSelected: _gender == g,
                              onSelected: () => setState(() => _gender = g),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Edad'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ageOptions
                        .map((a) => _buildChoiceChip(
                              label: a,
                              isSelected: _ageRange == a,
                              onSelected: () => setState(() => _ageRange = a),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Momento de la Noche'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _momentOptions
                        .map((m) => _buildChoiceChip(
                              label: m,
                              isSelected: _moment == m,
                              onSelected: () => setState(() => _moment = m),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Duración de la Atención'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _durationOptions
                        .map((d) => _buildChoiceChip(
                              label: d,
                              isSelected: _duration == d,
                              onSelected: () => setState(() => _duration = d),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('¿Cómo llega?'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _arrivalOptions
                        .map((arr) => _buildChoiceChip(
                              label: arr,
                              isSelected: _arrivalMode == arr,
                              onSelected: () =>
                                  setState(() => _arrivalMode = arr),
                            ))
                        .toList(),
                  ),
                  if (_arrivalMode == 'Acompañadx') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accompaniedByController,
                      decoration: const InputDecoration(
                        labelText: 'Acompañadx por...',
                        hintText: 'Ej: Pareja, primo, conocido',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // 2. Consumo de Sustancias
              _buildSectionCard(
                title: '2. Consumo de Sustancias',
                icon: Icons.medication_liquid_outlined,
                children: [
                  _buildLabel('¿Consumió algo?'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _consumedOptions
                        .map((opt) => _buildChoiceChip(
                              label: opt,
                              isSelected: _consumedSubstances == opt,
                              onSelected: () =>
                                  setState(() => _consumedSubstances = opt),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  if (_consumedSubstances == 'Si') ...[
                    Text(
                      'Sustancias y cantidades reportadas (tocá para activar y colocar cantidad):',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._officialSubstances.map((sub) {
                      final isSelected = _substanceQuantities.containsKey(sub);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primary.withValues(alpha: isDark ? 0.16 : 0.08)
                                : AppTheme.surfaceContainer(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? primary
                                  : AppTheme.borderColor(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: primary,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _substanceQuantities[sub] = '';
                                        } else {
                                          _substanceQuantities.remove(sub);
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      sub,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.textPrimaryColor(context)
                                            : AppTheme.textSecondaryColor(
                                                context),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    SizedBox(
                                      width: 130,
                                      child: TextFormField(
                                        initialValue:
                                            _substanceQuantities[sub],
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                          hintText: 'Cantidad (dedo, mg, ...)',
                                        ),
                                        onChanged: (val) {
                                          _substanceQuantities[sub] = val.trim();
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              if (sub == 'MDMA Pastilla' && isSelected) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _mdmaPillNameController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'MDMA Pastilla ¿cuál?*',
                                    hintText: 'Forma, color o logo de la pastilla',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),

                    // Opción "Otro" para sustancias
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Otra sustancia no listada:'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _otherSubstanceNameController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Sustancia',
                                    hintText: 'Nombre',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller:
                                      _otherSubstanceQuantityController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Cantidad',
                                    hintText: 'Dosis/Cant.',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildLabel('¿Es la primera vez que consume?'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Si', 'No', 'Desconocido']
                        .map((opt) => _buildChoiceChip(
                              label: opt,
                              isSelected: _isFirstTimeConsuming == opt,
                              onSelected: () => setState(
                                  () => _isFirstTimeConsuming = opt),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('¿Tiene alguna enfermedad de base?'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['No', 'Desconocido', 'Si']
                        .map((opt) => _buildChoiceChip(
                              label: opt,
                              isSelected: _hasUnderlyingCondition == opt,
                              onSelected: () => setState(
                                  () => _hasUnderlyingCondition = opt),
                            ))
                        .toList(),
                  ),
                  if (_hasUnderlyingCondition == 'Si') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _underlyingConditionDetailController,
                      decoration: const InputDecoration(
                        labelText: 'Especificar enfermedad de base',
                        hintText: 'Ej: Asma, cardiopatía, diabetes...',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // 3. Signos y Síntomas Físicos
              _buildSectionCard(
                title: '3. Signos y Síntomas Físicos',
                icon: Icons.health_and_safety_outlined,
                children: [
                  Text(
                    'Selección múltiple de signos observados o reportados:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _officialPhysicalSymptoms.map((sym) {
                      final isSelected = _physicalSymptoms.contains(sym);
                      return _buildToggleFilterChip(
                        label: sym,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _physicalSymptoms.remove(sym);
                            } else {
                              _physicalSymptoms.add(sym);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherPhysicalSymptomsController,
                    decoration: const InputDecoration(
                      labelText: '¿Algún otro signo / síntoma físico?',
                      hintText: 'Describir otros signos físicos...',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Signos Psicológicos / Emocionales
              _buildSectionCard(
                title: '4. Signos Psicológicos / Emocionales',
                icon: Icons.psychology_outlined,
                children: [
                  Text(
                    'Selección múltiple de estado emocional y conductual:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _officialPsychologicalSymptoms.map((sym) {
                      final isSelected = _psychologicalSymptoms.contains(sym);
                      return _buildToggleFilterChip(
                        label: sym,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _psychologicalSymptoms.remove(sym);
                            } else {
                              _psychologicalSymptoms.add(sym);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Intervención, Complejidad y Resolución
              _buildSectionCard(
                title: '5. Intervención y Resolución',
                icon: Icons.verified_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Equipo de salud'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildChoiceChip(
                                  label: 'Si',
                                  isSelected: _healthTeamIntervened,
                                  onSelected: () => setState(
                                      () => _healthTeamIntervened = true),
                                ),
                                const SizedBox(width: 8),
                                _buildChoiceChip(
                                  label: 'No',
                                  isSelected: !_healthTeamIntervened,
                                  onSelected: () => setState(
                                      () => _healthTeamIntervened = false),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Caso complejo'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildChoiceChip(
                                  label: 'Si',
                                  isSelected: _isComplexCase,
                                  onSelected: () =>
                                      setState(() => _isComplexCase = true),
                                ),
                                const SizedBox(width: 8),
                                _buildChoiceChip(
                                  label: 'No',
                                  isSelected: !_isComplexCase,
                                  onSelected: () =>
                                      setState(() => _isComplexCase = false),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Resolución del caso'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _resolutionOptions
                        .map((res) => _buildChoiceChip(
                              label: res,
                              isSelected: _resolution == res,
                              onSelected: () =>
                                  setState(() => _resolution = res),
                            ))
                        .toList(),
                  ),
                  if (_resolution == 'Otro') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _otherResolutionController,
                      decoration: const InputDecoration(
                        labelText: 'Especificar otra resolución',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _attendingStaffController,
                    decoration: const InputDecoration(
                      labelText: 'Vuelo que atendió',
                      hintText: 'Nombre del staff responsable',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _relevantInfoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Info relevante',
                      hintText: 'Notas adicionales sobre la intervención...',
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor(context),
                  ),
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

  Widget _buildToggleFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = AppTheme.primaryColor(context);
    final isDark = AppTheme.isDark(context);

    return PressableScale(
      onTap: onTap,
      targetScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.24 : 0.14)
              : (isDark
                  ? const Color(0xFF242424)
                  : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: isSelected ? primary : AppTheme.textMutedColor(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.emeraldDark)
                    : AppTheme.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
