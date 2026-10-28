import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_background.dart';
import '../../widgets/event_banner_image.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? event;

  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  final _requiredStaffController = TextEditingController(text: '15');

  String? _existingImageUrl;
  String? _newImageBase64;
  bool _imageRemoved = false;
  bool _isPickingImage = false;

  DateTime? _selectedDate;

  // Horarios por default requeridos: 14hs (inicio), 16hs (puertas), 01hs (cierre)
  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _doorsOpenTime = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 1, minute: 0);

  bool _isSaving = false;

  String? get _displayImage {
    if (_imageRemoved) return null;
    if (_newImageBase64 != null) {
      return 'data:image/jpeg;base64,$_newImageBase64';
    }
    return _existingImageUrl;
  }

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      final e = widget.event!;
      _nameController.text = e.name;
      _locationController.text = e.location;
      _addressController.text = e.address ?? '';
      _requiredStaffController.text = e.requiredStaffCount.toString();
      _selectedDate = e.date;
      _dateController.text = _formatDisplayDate(e.date);
      _startTime =
          _parseTimeOfDay(e.startTime) ?? const TimeOfDay(hour: 14, minute: 0);
      _doorsOpenTime = _parseTimeOfDay(e.doorsOpenTime) ??
          const TimeOfDay(hour: 16, minute: 0);
      _endTime =
          _parseTimeOfDay(e.endTime) ?? const TimeOfDay(hour: 1, minute: 0);

      if (e.imageUrl != null && e.imageUrl!.trim().isNotEmpty) {
        _existingImageUrl = e.imageUrl!.trim();
      }
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _requiredStaffController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDisplayDate(DateTime date) {
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

  Future<void> _pickDate() async {
    if (_isSaving) return;
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'AR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDisplayDate(picked);
      });
    }
  }

  Future<void> _pickTime({
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onSelected,
  }) async {
    if (_isSaving) return;
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 82,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final b64 = base64Encode(bytes);
        setState(() {
          _newImageBase64 = b64;
          _imageRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar la imagen: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _showImageSourcePicker() {
    if (_isSaving || _isPickingImage) return;
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final primary = AppTheme.primaryColor(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_library_outlined, color: primary),
                title: const Text(
                  'Elegir de la galería',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(source: ImageSource.gallery);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.camera_alt_outlined, color: primary),
                title: const Text(
                  'Tomar foto con la cámara',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(source: ImageSource.camera);
                },
              ),
              if (_displayImage != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorRed,
                  ),
                  title: const Text(
                    'Quitar imagen',
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _imageRemoved = true;
                      _newImageBase64 = null;
                      _existingImageUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    if (_selectedDate == null) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccioná la fecha del evento.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
    });

    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    final String? finalImage;
    if (_imageRemoved) {
      finalImage = null;
    } else if (_newImageBase64 != null) {
      finalImage = 'data:image/jpeg;base64,$_newImageBase64';
    } else {
      finalImage = _existingImageUrl;
    }

    final eventService = context.read<EventService>();
    final bool success;

    if (widget.event != null) {
      success = await eventService.updateEvent(
        eventId: widget.event!.id,
        name: _nameController.text.trim(),
        date: _selectedDate!,
        startTime: _formatTime(_startTime),
        doorsOpenTime: _formatTime(_doorsOpenTime),
        endTime: _formatTime(_endTime),
        location: _locationController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        imageUrl: finalImage,
        requiredStaffCount:
            int.tryParse(_requiredStaffController.text.trim()) ?? 15,
        currentUser: currentUser,
      );
    } else {
      success = await eventService.createEvent(
        name: _nameController.text.trim(),
        date: _selectedDate!,
        startTime: _formatTime(_startTime),
        doorsOpenTime: _formatTime(_doorsOpenTime),
        endTime: _formatTime(_endTime),
        location: _locationController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        imageUrl: finalImage,
        requiredStaffCount:
            int.tryParse(_requiredStaffController.text.trim()) ?? 15,
        currentUser: currentUser,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event != null
                  ? '✓ Evento actualizado exitosamente'
                  : '✓ Evento publicado exitosamente',
            ),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event != null
                  ? 'No tenés permisos para editar eventos.'
                  : 'No tenés permisos para crear eventos.',
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final surfaceContainer = AppTheme.surfaceContainer(context);
    final borderColor = AppTheme.borderColor(context);

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
            onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
          ),
        ),
        title: AppHeaderTitle(
          title: isEditing ? 'Editar Evento' : 'Crear Nuevo Evento',
        ),
        actions: [
          FilledButton(
            style: AppTheme.headerActionButtonStyle(context),
            onPressed: _isSaving ? null : _submit,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isSaving
                  ? Row(
                      key: const ValueKey('saving'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            strokeCap: StrokeCap.round,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Guardando...'),
                      ],
                    )
                  : Row(
                      key: const ValueKey('idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(isEditing ? 'Guardar' : 'Publicar'),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.paddingOf(context).bottom + 48,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. CONTENEDOR DE IMAGEN CON MISMO ESTILO DE DISEÑO QUE LOS INPUTS
                    _buildInputStyledImageContainer(context),
                    const SizedBox(height: 16),

                    // 2. Nombre del Evento
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Evento *',
                        hintText: 'Ej: Fiesta Vuelo Controlado #12',
                        prefixIcon: Icon(Icons.event, color: primary),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'El nombre es obligatorio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Fecha del Evento
                    TextFormField(
                      readOnly: true,
                      enabled: !_isSaving,
                      onTap: _pickDate,
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'Fecha del Evento *',
                        hintText: 'Seleccionar fecha del evento',
                        prefixIcon: Icon(Icons.calendar_month, color: primary),
                        suffixIcon: Icon(
                          Icons.edit_calendar,
                          color: textSecondary,
                          size: 20,
                        ),
                      ),
                      validator: (_) {
                        if (_selectedDate == null) {
                          return 'La fecha es obligatoria.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Lugar / Predio (Obligatorio)
                    TextFormField(
                      controller: _locationController,
                      enabled: !_isSaving,
                      decoration: InputDecoration(
                        labelText: 'Lugar / Predio *',
                        hintText: 'Ej: Complejo C Art Media',
                        prefixIcon: Icon(Icons.place_outlined, color: primary),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'El lugar o predio es obligatorio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5. Dirección
                    TextFormField(
                      controller: _addressController,
                      enabled: !_isSaving,
                      decoration: InputDecoration(
                        labelText: 'Dirección (opcional)',
                        hintText: 'Ej: Corrientes 6271, Chacarita, CABA',
                        prefixIcon:
                            Icon(Icons.signpost_outlined, color: primary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 6. Horarios: Inicio (14hs), Puertas (16hs), Cierre (01hs)
                    Text(
                      'Horarios de Guardia y Función',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeItem(
                            label: 'Inicio',
                            time: _startTime,
                            icon: Icons.play_arrow_outlined,
                            onTap: () => _pickTime(
                              initialTime: _startTime,
                              onSelected: (t) => setState(() => _startTime = t),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TimeItem(
                            label: 'Puertas',
                            time: _doorsOpenTime,
                            icon: Icons.meeting_room_outlined,
                            onTap: () => _pickTime(
                              initialTime: _doorsOpenTime,
                              onSelected: (t) =>
                                  setState(() => _doorsOpenTime = t),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TimeItem(
                            label: 'Cierre',
                            time: _endTime,
                            icon: Icons.nightlight_outlined,
                            onTap: () => _pickTime(
                              initialTime: _endTime,
                              onSelected: (t) => setState(() => _endTime = t),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 7. Campo de Miembros en contenedor estilo Input
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  size: 20,
                                  color: primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Miembros de staff necesarios',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Stepper numérico a la derecha
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  tooltip: 'Disminuir cupo',
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          final val = int.tryParse(
                                                  _requiredStaffController
                                                      .text) ??
                                              15;
                                          if (val > 1) {
                                            setState(() =>
                                                _requiredStaffController.text =
                                                    '${val - 1}');
                                          }
                                        },
                                ),
                                SizedBox(
                                  width: 36,
                                  child: TextFormField(
                                    controller: _requiredStaffController,
                                    enabled: !_isSaving,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                      filled: false,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  tooltip: 'Aumentar cupo',
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          final val = int.tryParse(
                                                  _requiredStaffController
                                                      .text) ??
                                              15;
                                          setState(() =>
                                              _requiredStaffController.text =
                                                  '${val + 1}');
                                        },
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
            ),
          ),
        ),
      ),
    );
  }

  /// Contenedor de imagen con exactamente el mismo diseño visual que los demás inputs
  Widget _buildInputStyledImageContainer(BuildContext context) {
    final imageToDisplay = _displayImage;
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final surfaceContainer = AppTheme.surfaceContainer(context);
    final borderColor = AppTheme.borderColor(context);

    return Material(
      color: surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: (_isPickingImage || _isSaving) ? null : _showImageSourcePicker,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 20,
                    color: primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Banner o Flyer del Evento',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          imageToDisplay != null
                              ? 'Tocá para reemplazar o quitar la imagen'
                              : 'Opcional • Tocá para elegir de galería o cámara',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isPickingImage)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        strokeCap: StrokeCap.round,
                        color: primary,
                      ),
                    )
                  else if (imageToDisplay == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Subir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                ],
              ),
              if (imageToDisplay != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    EventBannerImage(
                      imageSource: imageToDisplay,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.78),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: const Text(
                              'Cambiar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: (_isPickingImage || _isSaving)
                                ? null
                                : _showImageSourcePicker,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.78),
                              foregroundColor: AppTheme.errorRed,
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.all(8),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Quitar imagen',
                            onPressed: _isSaving
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _imageRemoved = true;
                                      _newImageBase64 = null;
                                      _existingImageUrl = null;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeItem({
    required this.label,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final surfaceContainer = AppTheme.surfaceContainer(context);
    final borderColor = AppTheme.borderColor(context);

    return Material(
      color: surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(icon, size: 16, color: primary),
                  const SizedBox(width: 4),
                  Text(
                    '$hour:$minute',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
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
}
