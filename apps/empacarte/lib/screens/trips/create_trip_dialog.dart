import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/packing_item.dart';
import '../../models/trip.dart';
import '../../models/trip_leg.dart';
import '../../repositories/packing_presets.dart';
import '../../repositories/storage_repository.dart';

class CreateTripDialog extends StatefulWidget {
  final StorageRepository storage;

  const CreateTripDialog({
    super.key,
    required this.storage,
  });

  @override
  State<CreateTripDialog> createState() => _CreateTripDialogState();
}

class _CreateTripDialogState extends State<CreateTripDialog> {
  final _destController = TextEditingController();
  final _codeController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  final TravelMode _mode = TravelMode.flight;
  final TripPurpose _purpose = TripPurpose.vacation;
  DestinationClimate _climate = DestinationClimate.temperate;
  bool _hasLaundry = false;

  // Multi-destination itinerary support
  bool _isMultiDestination = false;
  final List<TripLeg> _legs = [];

  int _currentStep = 0; // 0 = Trip details, 1 = Recommended luggage review
  List<PackingItem> _generatedItems = [];
  final Set<String> _deselectedItemIds = {};

  static const _uuid = Uuid();

  @override
  void dispose() {
    _destController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  int get _durationDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff <= 0 ? 1 : diff;
  }

  Set<DestinationClimate> get _selectedClimates {
    if (_isMultiDestination && _legs.isNotEmpty) {
      return _legs.map((l) => l.climate).toSet();
    }
    return {_climate};
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart ? DateTime.now() : _startDate;
    final last = DateTime.now().add(const Duration(days: 365 * 3));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addStopDialog() async {
    final isSpanish = AppLocalizations.of(context).locale.languageCode == 'es';
    final nameCtrl = TextEditingController();
    final hotelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    DestinationClimate stopClimate = DestinationClimate.temperate;

    DateTime legStart = _legs.isNotEmpty ? _legs.last.endDate : _startDate;
    DateTime legEnd = legStart.add(const Duration(days: 3));
    if (legEnd.isAfter(_endDate)) {
      legEnd = _endDate;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            isSpanish ? 'Agregar Escala / Destino' : 'Add Stop / Destination',
            style: AppTypography.subheadSerif(color: AppColors.burgundyBase),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Ciudad / Destino' : 'City / Destination',
                    hintText: 'Ej. Florencia, Italia',
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hotelCtrl,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Hotel o Alojamiento (Opcional)' : 'Hotel / Stay (Optional)',
                    hintText: 'Ej. Grand Hotel Central',
                    prefixIcon: const Icon(Icons.hotel_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: isSpanish ? 'Dirección de Check-in (Opcional)' : 'Check-in Address (Optional)',
                    hintText: 'Ej. Via Roma 42',
                    prefixIcon: const Icon(Icons.pin_drop_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSpanish ? 'Clima en esta parada' : 'Climate at this stop',
                  style: AppTypography.caption(color: AppColors.textLightSecondary, medium: true),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: DestinationClimate.values.map((c) {
                    final isSel = stopClimate == c;
                    return ChoiceChip(
                      label: Text(
                        c == DestinationClimate.warm
                            ? '☀️ Cálido'
                            : c == DestinationClimate.temperate
                                ? '⛅ Templado'
                                : c == DestinationClimate.cold
                                    ? '❄️ Frío'
                                    : '🌧️ Lluvioso',
                        style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null),
                      ),
                      selected: isSel,
                      selectedColor: AppColors.burgundyBase,
                      onSelected: (val) {
                        if (val) setDlgState(() => stopClimate = c);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final destName = nameCtrl.text.trim();
                if (destName.isEmpty) return;

                final code = destName.length >= 3 ? destName.substring(0, 3).toUpperCase() : 'STOP';
                final newLeg = TripLeg(
                  id: _uuid.v4(),
                  destination: destName,
                  destinationCode: code,
                  startDate: legStart,
                  endDate: legEnd,
                  climate: stopClimate,
                  hotelName: hotelCtrl.text.trim().isEmpty ? null : hotelCtrl.text.trim(),
                  hotelAddress: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                  checkInTime: '15:00',
                  checkOutTime: '11:00',
                );

                setState(() {
                  _legs.add(newLeg);
                });
                Navigator.of(ctx).pop();
              },
              child: Text(isSpanish ? 'Agregar' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToRecommendedLuggage() {
    if (_destController.text.trim().isEmpty && _legs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresá la ciudad o destino principal')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final tempTripId = _uuid.v4();
    final isSpanish = AppLocalizations.of(context).locale.languageCode == 'es';

    final items = PackingPresets.generateSmartList(
      tripId: tempTripId,
      purpose: _purpose,
      durationDays: _durationDays,
      climate: _climate,
      climates: _selectedClimates,
      hasLaundryAccess: _hasLaundry,
      alwaysPackItemNames: widget.storage.alwaysPackItems,
      isSpanish: isSpanish,
    );

    setState(() {
      _generatedItems = items;
      _deselectedItemIds.clear();
      _currentStep = 1;
    });
  }

  void _confirmAndCreateTrip() async {
    HapticFeedback.heavyImpact();

    final tripId = _uuid.v4();
    final dest = _destController.text.trim().isNotEmpty
        ? _destController.text.trim()
        : (_legs.isNotEmpty ? _legs.first.destination : 'Viaje');
    final destCode = _codeController.text.trim().isEmpty
        ? (dest.length >= 3 ? dest.substring(0, 3).toUpperCase() : 'DEST')
        : _codeController.text.trim().toUpperCase();

    // Prepare legs list
    List<TripLeg> finalLegs = [];
    if (_isMultiDestination && _legs.isNotEmpty) {
      finalLegs = List.from(_legs);
      // Ensure first leg covers destination if not explicitly added
      if (!finalLegs.any((l) => l.destination.toLowerCase() == dest.toLowerCase())) {
        finalLegs.insert(
          0,
          TripLeg(
            id: _uuid.v4(),
            destination: dest,
            destinationCode: destCode,
            startDate: _startDate,
            endDate: finalLegs.first.startDate,
            climate: _climate,
          ),
        );
      }
    }

    final newTrip = Trip(
      id: tripId,
      destination: dest,
      originCode: 'EZE',
      destinationCode: destCode,
      startDate: _startDate,
      endDate: _endDate,
      travelMode: _mode,
      purpose: _purpose,
      climate: _climate,
      legs: finalLegs,
    );

    // Filter confirmed items and assign the real tripId
    final confirmedItems = _generatedItems
        .where((item) => !_deselectedItemIds.contains(item.id))
        .map((item) => item.copyWith(name: item.name))
        .toList();

    // Map each item to the actual tripId
    final finalItems = confirmedItems.map((item) {
      return PackingItem(
        id: _uuid.v4(),
        tripId: tripId,
        name: item.name,
        compartment: item.compartment,
        category: item.category,
        quantity: item.quantity,
        weightKg: item.weightKg,
        isPacked: false,
        isAlwaysPack: item.isAlwaysPack,
      );
    }).toList();

    await widget.storage.addTrip(newTrip, finalItems);

    if (mounted) {
      Navigator.of(context).pop(newTrip);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpanish = t.locale.languageCode == 'es';

    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final primaryAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _currentStep == 0 ? Icons.flight_takeoff_rounded : Icons.auto_awesome_rounded,
              color: primaryAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentStep == 0
                      ? (isSpanish ? 'Nuevo Viaje' : 'New Trip')
                      : (isSpanish ? 'Equipaje Recomendado' : 'Smart Luggage'),
                  style: AppTypography.subheadSerif(color: textPrimary),
                ),
                Text(
                  _currentStep == 0
                      ? (isSpanish ? 'Paso 1 de 2 · Destinos y Clima' : 'Step 1 of 2 · Route & Weather')
                      : (isSpanish ? 'Paso 2 de 2 · Asistente de valija' : 'Step 2 of 2 · Luggage Assistant'),
                  style: AppTypography.caption(color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _currentStep == 0
              ? _buildStep0Details(isDark, primaryAccent, textSecondary, isSpanish)
              : _buildStep1LuggageReview(context, t, isDark, isSpanish, primaryAccent, textSecondary),
        ),
      ),
      actions: [
        if (_currentStep == 0) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.t('btn_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _proceedToRecommendedLuggage,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isSpanish ? 'Ver Equipaje' : 'Review Luggage'),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: Text(isSpanish ? 'Atrás' : 'Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stampEmeraldLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _confirmAndCreateTrip,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, size: 18),
                const SizedBox(width: 6),
                Text(isSpanish ? 'Confirmar y Guardar' : 'Confirm & Save'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep0Details(
    bool isDark,
    Color primaryAccent,
    Color textSecondary,
    bool isSpanish,
  ) {
    final startStr = DateFormat('dd MMM yyyy').format(_startDate);
    final endStr = DateFormat('dd MMM yyyy').format(_endDate);

    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _destController,
            decoration: InputDecoration(
              labelText: isSpanish ? 'Destino Principal (Ciudad, País)' : 'Primary Destination (City, Country)',
              hintText: 'Ej. Tokyo, Japón',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: isSpanish ? 'Código IATA (Opcional)' : 'IATA Airport Code (Optional)',
              hintText: 'HND / CDG / JFK / BCN',
              prefixIcon: const Icon(Icons.flight_land_rounded),
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),

          // Date Selectors
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: textSecondary.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isSpanish ? 'Ida' : 'Departure', style: AppTypography.caption(color: textSecondary)),
                        const SizedBox(height: 2),
                        Text(startStr, style: AppTypography.bodySmall(color: primaryAccent, medium: true)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: textSecondary.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isSpanish ? 'Vuelta' : 'Return', style: AppTypography.caption(color: textSecondary)),
                        const SizedBox(height: 2),
                        Text(endStr, style: AppTypography.bodySmall(color: primaryAccent, medium: true)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Duration pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: primaryAccent),
                const SizedBox(width: 6),
                Text(
                  isSpanish ? 'Duración total: $_durationDays días' : 'Total duration: $_durationDays days',
                  style: AppTypography.caption(color: primaryAccent, medium: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Multi-destination Switch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.alt_route_rounded, color: primaryAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isSpanish ? 'Itinerario con múltiples paradas' : 'Multi-stop itinerary',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                          medium: true,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _isMultiDestination,
                      activeTrackColor: primaryAccent,
                      onChanged: (val) => setState(() => _isMultiDestination = val),
                    ),
                  ],
                ),
                if (_isMultiDestination) ...[
                  const SizedBox(height: 8),
                  Text(
                    isSpanish
                        ? 'Agregá cada ciudad o alojamiento para organizar check-in, check-out y clima individual.'
                        : 'Add each stop to organize check-in, check-out and climate per destination.',
                    style: AppTypography.caption(color: textSecondary),
                  ),
                  const SizedBox(height: 10),

                  // Legs chips
                  if (_legs.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _legs.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final leg = entry.value;
                        return Chip(
                          backgroundColor: primaryAccent.withValues(alpha: 0.12),
                          label: Text('${idx + 1}. ${leg.destination.split(',').first}', style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          onDeleted: () {
                            setState(() {
                              _legs.removeAt(idx);
                            });
                          },
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _addStopDialog,
                    icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                    label: Text(
                      isSpanish ? '+ Agregar Destino / Hotel' : '+ Add Destination / Hotel',
                      style: TextStyle(color: primaryAccent, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Climate Selector
          Text(
            isSpanish ? 'Clima en Destino Principal' : 'Primary Destination Climate',
            style: AppTypography.caption(color: textSecondary, medium: true),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildClimateChip(
                DestinationClimate.warm,
                '☀️ Cálido / Playa',
                '☀️ Warm & Beach',
                _climate == DestinationClimate.warm,
                primaryAccent,
              ),
              _buildClimateChip(
                DestinationClimate.temperate,
                '⛅ Templado',
                '⛅ Mild / Spring',
                _climate == DestinationClimate.temperate,
                primaryAccent,
              ),
              _buildClimateChip(
                DestinationClimate.cold,
                '❄️ Frío / Nieve',
                '❄️ Cold / Winter',
                _climate == DestinationClimate.cold,
                primaryAccent,
              ),
              _buildClimateChip(
                DestinationClimate.rainy,
                '🌧️ Lluvioso',
                '🌧️ Rainy / Wet',
                _climate == DestinationClimate.rainy,
                primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Laundry Rotation Switch (Backpacker feature)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              isSpanish ? 'Tengo acceso a lavandería' : 'Laundry access during trip',
              style: AppTypography.bodySmall(color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
            ),
            subtitle: Text(
              isSpanish ? 'Optimiza la ropa para rotar y lavar en destino' : 'Optimizes luggage size with clothes rotation',
              style: AppTypography.caption(color: textSecondary),
            ),
            value: _hasLaundry,
            activeTrackColor: primaryAccent,
            onChanged: (val) => setState(() => _hasLaundry = val),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateChip(
    DestinationClimate climate,
    String labelEs,
    String labelEn,
    bool isSelected,
    Color primaryAccent,
  ) {
    final isSpanish = AppLocalizations.of(context).locale.languageCode == 'es';
    return ChoiceChip(
      label: Text(
        isSpanish ? labelEs : labelEn,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : primaryAccent,
        ),
      ),
      selected: isSelected,
      selectedColor: primaryAccent,
      backgroundColor: isSelected ? primaryAccent : Colors.transparent,
      side: BorderSide(
        color: isSelected ? primaryAccent : primaryAccent.withValues(alpha: 0.3),
        width: 1.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _climate = climate;
        });
      },
    );
  }

  Widget _buildStep1LuggageReview(
    BuildContext context,
    AppLocalizations t,
    bool isDark,
    bool isSpanish,
    Color primaryAccent,
    Color textSecondary,
  ) {
    final isPro = widget.storage.isPro;
    final climatesCount = _selectedClimates.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: primaryAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSpanish
                        ? 'EmpacArte armó una sugerencia personalizada para tu viaje.'
                        : 'EmpacArte tailored a smart packing suggestion for your trip.',
                    style: AppTypography.caption(
                      color: primaryAccent,
                      medium: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Multi-climate indicator if applicable
          if (climatesCount > 1)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.stampCobaltLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alt_route_rounded, size: 16, color: AppColors.stampCobaltLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSpanish
                          ? 'Itinerario multi-clima: combinamos prendas para $climatesCount climas diferentes.'
                          : 'Multi-climate itinerary: consolidated gear for $climatesCount different climates.',
                      style: AppTypography.caption(color: AppColors.stampCobaltLight, medium: true),
                    ),
                  ),
                ],
              ),
            ),

          // Freemium vs PRO indicator banner
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isPro
                  ? AppColors.stampEmeraldLight.withValues(alpha: 0.12)
                  : (isDark ? AppColors.darkElevated : AppColors.parchmentElevated),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPro ? AppColors.stampEmeraldLight : textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPro ? Icons.stars_rounded : Icons.info_outline_rounded,
                  color: isPro ? AppColors.stampEmeraldLight : textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPro
                        ? (isSpanish
                            ? '👑 Modo PRO: Ítems organizados en 3 bultos con control de balanza.'
                            : '👑 PRO Mode: Compartmentalized in 3 bags with weight control.')
                        : (isSpanish
                            ? 'Lista inteligente unificada. Desbloqueá PRO para separar en Mochila, Carry-on y Bodega.'
                            : 'Unified smart list. Unlock PRO to split across Personal, Carry-on & Checked bags.'),
                    style: AppTypography.caption(
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      medium: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Text(
            isSpanish
                ? 'Revisá los ítems recomendados para $_durationDays días:'
                : 'Review recommended items for $_durationDays days:',
            style: AppTypography.caption(color: textSecondary),
          ),
          const SizedBox(height: 8),

          // Items List with selection toggles
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _generatedItems.length,
              itemBuilder: (context, idx) {
                final item = _generatedItems[idx];
                final isSelected = !_deselectedItemIds.contains(item.id);

                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: isSelected,
                  activeColor: AppColors.stampEmeraldLight,
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      decoration: isSelected ? null : TextDecoration.lineThrough,
                      color: isSelected
                          ? (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary)
                          : textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    '${item.compartment.name.toUpperCase()} · ${item.category.name}',
                    style: AppTypography.caption(color: textSecondary),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _deselectedItemIds.remove(item.id);
                      } else {
                        _deselectedItemIds.add(item.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
