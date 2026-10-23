import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../services/case_service.dart';
import '../../theme/app_theme.dart';

class CaseFormScreen extends StatefulWidget {
  final EventModel event;

  const CaseFormScreen({super.key, required this.event});

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _actionsController = TextEditingController();
  final _observationsController = TextEditingController();

  String _selectedGender = 'No especifica';
  String _selectedInterventionType = 'Contención emocional';
  final List<String> _selectedSubstances = [];
  bool _isSaving = false;

  final List<String> _genderOptions = [
    'Femenino',
    'Masculino',
    'No binario',
    'No especifica',
  ];

  final List<String> _interventionTypes = [
    'Contención emocional',
    'Hidratación y descanso',
    'Baja de presión',
    'Primeros auxilios',
    'Intoxicación',
    'Acompañamiento',
    'Derivación médica / SAME',
    'Otro',
  ];

  final List<String> _substanceOptions = [
    'Alcohol',
    'Cannabis',
    'Éxtasis / MDMA',
    'Psicodélicos / LSD / Hongos',
    'Cocaína',
    'Ketamina',
    'Benzodiacepinas',
    'Popper',
    'Ninguna / Desconoce',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _symptomsController.dispose();
    _actionsController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _toggleSubstance(String sub) {
    setState(() {
      if (_selectedSubstances.contains(sub)) {
        _selectedSubstances.remove(sub);
      } else {
        _selectedSubstances.add(sub);
      }
    });
  }

  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser == null) return;

    final caseService = context.read<CaseService>();
    await caseService.createCase(
      event: widget.event,
      currentUser: currentUser,
      personName: _nameController.text.trim(),
      personAge: _ageController.text.trim(),
      personGender: _selectedGender,
      interventionType: _selectedInterventionType,
      substances: _selectedSubstances,
      symptoms: _symptomsController.text.trim(),
      actionsTaken: _actionsController.text.trim(),
      observations: _observationsController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Ficha de caso guardada localmente.'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha de Caso'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppTheme.neonGreen, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Staff a cargo: ${currentUser?.fullName ?? ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Datos de la Persona Asistida
              const Text(
                '1. Datos de la Persona',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o Apodo',
                        hintText: 'Opcional si prefiere anonimato',
                        prefixIcon:
                            Icon(Icons.person, color: AppTheme.neonGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad',
                        hintText: 'Ej: 24',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'Género / Identidad',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _genderOptions.map((g) {
                  final isSelected = _selectedGender == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    selectedColor: AppTheme.neonGreen.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.neonGreen
                          : AppTheme.darkBorder,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.neonGreen
                          : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedGender = g);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 2. Tipo de Intervención
              const Text(
                '2. Tipo de Intervención *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interventionTypes.map((type) {
                  final isSelected = _selectedInterventionType == type;
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: AppTheme.neonGreen.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.neonGreen
                          : AppTheme.darkBorder,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.neonGreen
                          : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedInterventionType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 3. Sustancias Involucradas (Opcional)
              const Text(
                '3. Sustancias Involucradas (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Podés seleccionar múltiples o ninguna si la persona no consume o no refiere.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _substanceOptions.map((sub) {
                  final isSelected = _selectedSubstances.contains(sub);
                  return FilterChip(
                    label: Text(sub),
                    selected: isSelected,
                    selectedColor: AppTheme.neonGreen.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.neonGreen
                          : AppTheme.darkBorder,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.neonGreen
                          : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => _toggleSubstance(sub),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 4. Síntomas / Estado Clínico
              const Text(
                '4. Síntomas y Estado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _symptomsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Síntomas / Motivo de consulta *',
                  hintText: 'Ej: Mareos, deshidratación, angustia, sobrecalentamiento...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Por favor describí brevemente el estado o síntoma.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 5. Acciones Realizadas
              const Text(
                '5. Acciones Realizadas por el Staff',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _actionsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Intervención / Cuidado brindado *',
                  hintText: 'Ej: Suministro de agua fresca, reposo 20 min en carpa, escucha activa...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Por favor indicá qué acciones de cuidado se realizaron.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 6. Observaciones
              const Text(
                '6. Observaciones o Derivación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _observationsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observaciones adicionales (opcional)',
                  hintText: 'Ej: Se retiró acompañada por amigas; o se derivó a ambulancia SAME.',
                ),
              ),
              const SizedBox(height: 32),

              // Botón Guardar Caso
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('GUARDAR FICHA DE CASO'),
                onPressed: _isSaving ? null : _saveCase,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
