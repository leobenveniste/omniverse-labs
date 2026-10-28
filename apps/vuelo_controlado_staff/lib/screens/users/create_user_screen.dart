import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_background.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _docNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _docType = 'DNI';
  DateTime _birthDate = DateTime(1998, 1, 1);
  final List<String> _selectedRoles = [AppRoles.miembro];
  bool _isSaving = false;

  final List<String> _docTypes = ['DNI', 'Pasaporte', 'Cédula de Identidad'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _docNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatBirthDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1940),
      lastDate:
          DateTime.now().subtract(const Duration(days: 365 * 16)), // Min 16 años
      locale: const Locale('es', 'AR'),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _toggleRole(String role) {
    if (role == AppRoles.miembro) return; // No se puede sacar
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final authService = context.read<AuthService>();
    final success = await authService.createUser(
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      documentType: _docType,
      documentNumber: _docNumberController.text.trim(),
      birthDate: _birthDate,
      phone: _phoneController.text.trim(),
      initialRoles: _selectedRoles,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Usuario creado! Contraseña inicial: ${_docNumberController.text.trim()}',
            ),
            backgroundColor: AppTheme.neonGreen,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(authService.errorMessage ?? 'Error al crear usuario.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final surface = AppTheme.surfaceContainer(context);
    final border = AppTheme.borderColor(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            style: AppTheme.headerIconButtonStyle(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            tooltip: 'Volver',
            onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const AppHeaderTitle(title: 'Alta de Usuario'),
        actions: [
          FilledButton.icon(
            style: AppTheme.headerActionButtonStyle(context),
            onPressed: _isSaving ? null : _submit,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isSaving
                  ? const SizedBox(
                      key: ValueKey('saving'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.check_rounded,
                      key: ValueKey('idle'),
                      size: 18,
                    ),
            ),
            label: Text(_isSaving ? 'Creando...' : 'Crear'),
          ),
        ],
      ),
      body: AppBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: surface,
                        child: Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nombre y Apellido
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            enabled: !_isSaving,
                            decoration: InputDecoration(
                              labelText: 'Nombre *',
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: primary,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              labelText: 'Apellido *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tipo y Número de Documento
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<String>(
                            initialValue: _docType,
                            dropdownColor: theme.colorScheme.surface,
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                            ),
                            items: _docTypes
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ))
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _docType = val);
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _docNumberController,
                            enabled: !_isSaving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Número de Documento *',
                              hintText: 'Ej: 40123456',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'La contraseña inicial del usuario se generará igual a su número de documento.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fecha de Nacimiento
                    Text(
                      'Fecha de Nacimiento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isSaving ? null : _pickBirthDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cake_outlined, color: primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _formatBirthDate(_birthDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              color: textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico *',
                        hintText: 'miembro@vuelocontrolado.org',
                        prefixIcon:
                            Icon(Icons.email_outlined, color: primary),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (!v.contains('@')) return 'Email no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono de contacto *',
                        hintText: '+54 9 11 1234-5678',
                        prefixIcon:
                            Icon(Icons.phone_outlined, color: primary),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 24),

                    // Roles Asignados
                    Text(
                      'Roles Asignados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Por defecto todos tienen rol Miembro (inamovible). Podés asignar roles complementarios:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppRoles.allRoles.map((role) {
                        final isMiembro = role == AppRoles.miembro;
                        final isSelected = _selectedRoles.contains(role);

                        return FilterChip(
                          showCheckmark: false,
                          label: Text(role),
                          selected: isSelected,
                          selectedColor: primary.withValues(alpha: 0.18),
                          side: BorderSide(
                            color: isSelected ? primary : border,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? primary : textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (isMiembro || _isSaving)
                              ? null
                              : (_) => _toggleRole(role),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
