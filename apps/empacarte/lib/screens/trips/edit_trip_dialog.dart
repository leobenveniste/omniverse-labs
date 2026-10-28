import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/trip.dart';
import '../../models/trip_leg.dart';
import '../../repositories/storage_repository.dart';

class EditTripDialog extends StatefulWidget {
  final Trip trip;
  final StorageRepository storage;

  const EditTripDialog({
    super.key,
    required this.trip,
    required this.storage,
  });

  static Future<Trip?> show(BuildContext context, {required Trip trip, required StorageRepository storage}) {
    HapticFeedback.lightImpact();
    return showDialog<Trip>(
      context: context,
      builder: (_) => EditTripDialog(trip: trip, storage: storage),
    );
  }

  @override
  State<EditTripDialog> createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> {
  late final TextEditingController _destController;
  late final TextEditingController _codeController;
  late final TextEditingController _hotelController;
  late DateTime _startDate;
  late DateTime _endDate;
  late DestinationClimate _climate;
  late TravelMode _mode;
  late List<TripLeg> _legs;

  @override
  void initState() {
    super.initState();
    _destController = TextEditingController(text: widget.trip.destination);
    _codeController = TextEditingController(text: widget.trip.destinationCode);
    _hotelController = TextEditingController(text: widget.trip.hotelAddress ?? '');
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
    _climate = widget.trip.climate;
    _mode = widget.trip.travelMode;
    _legs = List.from(widget.trip.legs);
  }

  @override
  void dispose() {
    _destController.dispose();
    _codeController.dispose();
    _hotelController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final first = DateTime(2020);
    final last = DateTime.now().add(const Duration(days: 365 * 4));

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

  void _saveChanges() async {
    final dest = _destController.text.trim().isEmpty ? widget.trip.destination : _destController.text.trim();
    final code = _codeController.text.trim().isEmpty
        ? (dest.length >= 3 ? dest.substring(0, 3).toUpperCase() : 'DEST')
        : _codeController.text.trim().toUpperCase();

    final updated = widget.trip.copyWith(
      destination: dest,
      destinationCode: code,
      startDate: _startDate,
      endDate: _endDate,
      climate: _climate,
      travelMode: _mode,
      hotelAddress: _hotelController.text.trim().isEmpty ? null : _hotelController.text.trim(),
      legs: _legs,
    );

    await widget.storage.updateTrip(updated);
    HapticFeedback.mediumImpact();

    if (mounted) {
      Navigator.of(context).pop(updated);
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

    final startStr = DateFormat('dd MMM yyyy').format(_startDate);
    final endStr = DateFormat('dd MMM yyyy').format(_endDate);

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.edit_calendar_rounded, color: primaryAccent, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSpanish ? 'Editar Viaje' : 'Edit Trip',
              style: AppTypography.subheadSerif(color: textPrimary),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _destController,
                decoration: InputDecoration(
                  labelText: isSpanish ? 'Destino' : 'Destination',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: isSpanish ? 'Código IATA' : 'IATA Code',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.flight_land_rounded),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: textSecondary.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isSpanish ? 'Salida' : 'Departure', style: AppTypography.caption(color: textSecondary)),
                            const SizedBox(height: 2),
                            Text(startStr, style: AppTypography.bodySmall(color: primaryAccent, medium: true)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: textSecondary.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isSpanish ? 'Regreso' : 'Return', style: AppTypography.caption(color: textSecondary)),
                            const SizedBox(height: 2),
                            Text(endStr, style: AppTypography.bodySmall(color: primaryAccent, medium: true)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Climate
              Text(
                isSpanish ? 'Clima en destino:' : 'Destination climate:',
                style: AppTypography.caption(color: textSecondary, medium: true),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: DestinationClimate.values.map((c) {
                  final isSel = _climate == c;
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
                    selectedColor: primaryAccent,
                    onSelected: (val) {
                      if (val) setState(() => _climate = c);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Hotel address
              TextField(
                controller: _hotelController,
                decoration: InputDecoration(
                  labelText: isSpanish ? 'Alojamiento / Dirección' : 'Hotel / Address',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.hotel_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.t('btn_cancel')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAccent,
            foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
          ),
          onPressed: _saveChanges,
          child: Text(isSpanish ? 'Guardar Cambios' : 'Save Changes'),
        ),
      ],
    );
  }
}
