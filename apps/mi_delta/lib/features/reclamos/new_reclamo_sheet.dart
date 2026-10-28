import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/municipality_config.dart';
import '../../providers/app_providers.dart';

class NewReclamoSheet extends ConsumerStatefulWidget {
  final String? initialCategory;

  const NewReclamoSheet({super.key, this.initialCategory});

  static Future<void> show(BuildContext context, {String? initialCategory}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewReclamoSheet(initialCategory: initialCategory),
    );
  }

  @override
  ConsumerState<NewReclamoSheet> createState() => _NewReclamoSheetState();
}

class _NewReclamoSheetState extends ConsumerState<NewReclamoSheet> {
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  late String _selectedCategory;
  String _selectedLocality = MunicipalityConfig.localities.first;
  bool _photoAttached = false;
  bool _submitted = false;
  String _newCode = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? MunicipalityConfig.categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completá título, dirección y detalle'),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    ref.read(reclamosProvider.notifier).addReclamo(
          title: _titleController.text.trim(),
          category: _selectedCategory,
          address: _addressController.text.trim(),
          locality: _selectedLocality,
          description: _descController.text.trim(),
        );

    setState(() {
      _newCode = 'REC-${(1000 + (DateTime.now().millisecond * 9)).clamp(1000, 9999)}';
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _submitted ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 54),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Reclamo Ingresado con Éxito!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Fue recibido en el sistema municipal y se notificará a la cuadrilla de la zona.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              const Text(
                'CÓDIGO DE SEGUIMIENTO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _newCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Podés seguir su estado desde la pestaña de Reportes.',
                style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Listo, volver a la app',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Nuevo Reporte Cívico',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Category dropdown
        const Text(
          'Categoría del Incidente',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: MunicipalityConfig.categories.contains(_selectedCategory)
                  ? _selectedCategory
                  : MunicipalityConfig.categories.first,
              isExpanded: true,
              dropdownColor: AppColors.surfaceContainerLowest,
              icon: const Icon(Icons.expand_more_rounded, color: AppColors.primary),
              items: MunicipalityConfig.categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 13, color: AppColors.onSurface, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Title
        const Text(
          'Título breve del problema',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _titleController,
          style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Ej: Luminaria apagada en la esquina',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Locality & Address
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Barrio / Zona',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLocality,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceContainerLowest,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        items: MunicipalityConfig.localities.map((l) {
                          return DropdownMenuItem(
                            value: l,
                            child: Text(
                              l,
                              style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedLocality = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calle y Altura / Referencia',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Ej: Av. Cazón 1240',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Description
        const Text(
          'Detalle para la cuadrilla',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _descController,
          maxLines: 3,
          style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Describí lo que ocurre, horario o peligro inminente...',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 14),

        // Photo Attachment trigger
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _photoAttached = !_photoAttached);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _photoAttached ? AppColors.secondaryContainer.withValues(alpha: 0.35) : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _photoAttached ? AppColors.secondary : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _photoAttached ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                      size: 20,
                      color: _photoAttached ? AppColors.secondary : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _photoAttached ? '1 foto adjuntada (evidencia.jpg)' : 'Adjuntar fotografía del lugar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _photoAttached ? AppColors.onSecondaryContainer : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  _photoAttached ? 'Quitar' : 'Opcional',
                  style: TextStyle(
                    fontSize: 11,
                    color: _photoAttached ? AppColors.emergency : AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Submit Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Enviar Reporte al Municipio',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
