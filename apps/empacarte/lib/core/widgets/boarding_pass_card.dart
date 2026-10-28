import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trip.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'perforated_divider.dart';
import 'tactile_pressable.dart';

class BoardingPassCard extends StatelessWidget {
  final Trip trip;
  final int totalItems;
  final int packedItems;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onItineraryTap;
  final VoidCallback? onEditTap;

  const BoardingPassCard({
    super.key,
    required this.trip,
    required this.totalItems,
    required this.packedItems,
    required this.onTap,
    required this.onLongPress,
    this.onItineraryTap,
    this.onEditTap,
  });

  IconData _modeIcon() {
    switch (trip.travelMode) {
      case TravelMode.flight:
        return Icons.flight_takeoff_rounded;
      case TravelMode.train:
        return Icons.train_rounded;
      case TravelMode.car:
        return Icons.directions_car_rounded;
      case TravelMode.ship:
        return Icons.directions_boat_rounded;
      case TravelMode.backpack:
        return Icons.hiking_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpanish = t.locale.languageCode == 'es';

    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.parchmentBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final accentGold = isDark ? AppColors.goldFoil : AppColors.burgundyBase;

    final progressRatio = totalItems > 0 ? (packedItems / totalItems).clamp(0.0, 1.0) : 0.0;
    final is100Percent = totalItems > 0 && packedItems == totalItems;

    final formattedDate = DateFormat('dd MMM yyyy').format(trip.startDate).toUpperCase();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeLeg = trip.activeLeg(today);

    return TactilePressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Carrier & Destination Header)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_modeIcon(), color: accentGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.isMultiDestination ? trip.routeDisplay : trip.destination,
                          style: AppTypography.subheadSerif(color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: AppTypography.monoCaption(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Countdown chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: trip.isDepartsToday
                          ? AppColors.stampCrimsonLight
                          : (isDark ? AppColors.darkElevated : AppColors.parchmentElevated),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: trip.isDepartsToday
                            ? AppColors.stampCrimsonLight
                            : borderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      trip.isDepartsToday
                          ? t.t('trips_departs_today')
                          : '${trip.daysUntilDeparture} ${t.t('trips_countdown_days')}',
                      style: AppTypography.caption(
                        color: trip.isDepartsToday ? Colors.white : accentGold,
                        medium: true,
                      ),
                    ),
                  ),
                  if (onEditTap != null) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onEditTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: accentGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit_outlined, size: 16, color: accentGold),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Multi-destination itinerary summary banner if applicable
            if (trip.isMultiDestination)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentGold.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alt_route_rounded, size: 14, color: accentGold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activeLeg != null
                              ? (isSpanish
                                  ? 'En destino: ${activeLeg.destination.split(",").first}'
                                  : 'Active stop: ${activeLeg.destination.split(",").first}')
                              : '${trip.legs.length} ${isSpanish ? "destinos en ruta" : "stops on route"}',
                          style: AppTypography.caption(color: accentGold, medium: true),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onItineraryTap != null)
                        InkWell(
                          onTap: onItineraryTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              isSpanish ? 'Ver ruta ➔' : 'View route ➔',
                              style: AppTypography.caption(color: accentGold, medium: true),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Middle Route section (Origin ✈ Destination)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.t('trips_origin'), style: AppTypography.caption(color: textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        trip.originCode,
                        style: AppTypography.monoBody(color: textPrimary, medium: true).copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Icon(
                            trip.isMultiDestination ? Icons.alt_route_rounded : Icons.arrow_forward_rounded,
                            color: accentGold,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trip.isMultiDestination
                                ? '${trip.legs.length} STOPS'
                                : trip.purpose.name.toUpperCase(),
                            style: AppTypography.monoCaption(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(t.t('trips_dest'), style: AppTypography.caption(color: textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        trip.destinationCode,
                        style: AppTypography.monoBody(color: textPrimary, medium: true).copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Perforated Ticket Divider with Punch Notches
            PerforatedDivider(
              notchColor: scaffoldBg,
              dashColor: borderColor,
            ),

            // Bottom Packing Progress Bar & Itinerary Action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            is100Percent ? Icons.verified_rounded : Icons.luggage_rounded,
                            size: 16,
                            color: is100Percent
                                ? (isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight)
                                : accentGold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            is100Percent ? t.t('pack_cleared_badge') : t.t('trips_packed_progress'),
                            style: AppTypography.caption(
                              color: is100Percent
                                  ? (isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight)
                                  : textSecondary,
                              medium: true,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$packedItems/$totalItems',
                        style: AppTypography.monoCaption(color: textPrimary, medium: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 6,
                      backgroundColor: borderColor.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        is100Percent
                            ? (isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight)
                            : (isDark ? AppColors.goldFoil : AppColors.burgundyBase),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
