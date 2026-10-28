import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/trip.dart';
import '../../models/trip_leg.dart';
import '../../repositories/storage_repository.dart';

class ItineraryTimelineModal extends StatelessWidget {
  final Trip trip;
  final StorageRepository storage;
  final VoidCallback? onOpenCheckOutMode;

  const ItineraryTimelineModal({
    super.key,
    required this.trip,
    required this.storage,
    this.onOpenCheckOutMode,
  });

  static Future<void> show(
    BuildContext context, {
    required Trip trip,
    required StorageRepository storage,
    VoidCallback? onOpenCheckOutMode,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ItineraryTimelineModal(
        trip: trip,
        storage: storage,
        onOpenCheckOutMode: onOpenCheckOutMode,
      ),
    );
  }

  IconData _climateIcon(DestinationClimate c) {
    switch (c) {
      case DestinationClimate.warm:
        return Icons.wb_sunny_rounded;
      case DestinationClimate.temperate:
        return Icons.wb_cloudy_rounded;
      case DestinationClimate.cold:
        return Icons.ac_unit_rounded;
      case DestinationClimate.rainy:
        return Icons.beach_access_rounded;
    }
  }

  String _climateLabel(DestinationClimate c, bool isSpanish) {
    switch (c) {
      case DestinationClimate.warm:
        return isSpanish ? 'Cálido' : 'Warm';
      case DestinationClimate.temperate:
        return isSpanish ? 'Templado' : 'Mild';
      case DestinationClimate.cold:
        return isSpanish ? 'Frío' : 'Cold';
      case DestinationClimate.rainy:
        return isSpanish ? 'Lluvioso' : 'Rainy';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpanish = t.locale.languageCode == 'es';

    final bg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final border = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If trip has no legs, generate a virtual leg for display
    final legs = trip.legs.isNotEmpty
        ? trip.legs
        : [
            TripLeg(
              id: 'leg_single',
              destination: trip.destination,
              destinationCode: trip.destinationCode,
              startDate: trip.startDate,
              endDate: trip.endDate,
              climate: trip.climate,
              hotelAddress: trip.hotelAddress,
            ),
          ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: goldAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.alt_route_rounded, color: goldAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSpanish ? 'Itinerario de Destinos' : 'Trip Itinerary',
                        style: AppTypography.subheadSerif(color: textPrimary),
                      ),
                      Text(
                        '${legs.length} ${legs.length == 1 ? (isSpanish ? "destino" : "destination") : (isSpanish ? "destinos" : "destinations")} · ${trip.durationDays} ${isSpanish ? "días totales" : "total days"}',
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Timeline List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: legs.length,
              itemBuilder: (context, index) {
                final leg = legs[index];
                final isCurrent = leg.isCurrentlyActive(today);
                final isPast = DateTime(leg.endDate.year, leg.endDate.month, leg.endDate.day).isBefore(today);
                final isLast = index == legs.length - 1;

                final checkInStr = DateFormat('EEE dd MMM', t.locale.languageCode).format(leg.startDate);
                final checkOutStr = DateFormat('EEE dd MMM', t.locale.languageCode).format(leg.endDate);

                final isCheckInToday = leg.isCheckInDay(today);
                final isCheckOutToday = leg.isCheckOutDay(today);

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Column
                      SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? AppColors.stampEmeraldLight
                                    : (isPast
                                        ? textSecondary.withValues(alpha: 0.2)
                                        : goldAccent.withValues(alpha: 0.15)),
                                border: Border.all(
                                  color: isCurrent ? AppColors.stampEmeraldLight : goldAccent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? Colors.white : (isDark ? Colors.white : AppColors.burgundyDark),
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: isPast
                                      ? textSecondary.withValues(alpha: 0.2)
                                      : goldAccent.withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Leg Card
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkElevated : AppColors.parchmentElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.stampEmeraldLight
                                  : border,
                              width: isCurrent ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Destination Header & Climate
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      leg.destination,
                                      style: AppTypography.subheadSerif(color: textPrimary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: goldAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_climateIcon(leg.climate), size: 14, color: goldAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          _climateLabel(leg.climate, isSpanish),
                                          style: AppTypography.caption(color: goldAccent, medium: true),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Date & Duration Badge
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 14, color: textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$checkInStr ➔ $checkOutStr (${leg.durationDays} ${isSpanish ? "noches" : "nights"})',
                                      style: AppTypography.caption(color: textSecondary),
                                    ),
                                  ),
                                ],
                              ),

                              // Live Status Alert if active today
                              if (isCheckInToday) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.stampEmeraldLight.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.stampEmeraldLight.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.login_rounded, size: 16, color: AppColors.stampEmeraldLight),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isSpanish
                                              ? '¡Check-in hoy! Horario sugerido: ${leg.checkInTime ?? "15:00"}'
                                              : 'Check-in today! Suggested time: ${leg.checkInTime ?? "15:00"}',
                                          style: AppTypography.caption(
                                            color: AppColors.stampEmeraldLight,
                                            medium: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (isCheckOutToday) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.stampCrimsonLight.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.stampCrimsonLight.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout_rounded, size: 16, color: AppColors.stampCrimsonLight),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isSpanish
                                              ? '¡Check-out hoy! Antes de las ${leg.checkOutTime ?? "11:00"}'
                                              : 'Check-out today! Before ${leg.checkOutTime ?? "11:00"}',
                                          style: AppTypography.caption(
                                            color: AppColors.stampCrimsonLight,
                                            medium: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Accommodation info
                              if (leg.hotelName != null && leg.hotelName!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.hotel_rounded, size: 14, color: textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        leg.hotelName!,
                                        style: AppTypography.bodySmall(color: textPrimary, medium: true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (leg.hotelAddress != null && leg.hotelAddress!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 14, color: textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        leg.hotelAddress!,
                                        style: AppTypography.caption(color: textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (leg.notes != null && leg.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '📌 ${leg.notes}',
                                  style: AppTypography.caption(color: textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
