import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/destination_image_helper.dart';
import '../widgets/tactile_pressable.dart';
import '../../models/trip.dart';

class UpcomingTripBanner extends StatelessWidget {
  final Trip trip;
  final int totalItems;
  final int packedItems;
  final VoidCallback onTap;

  const UpcomingTripBanner({
    super.key,
    required this.trip,
    required this.totalItems,
    required this.packedItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = totalItems > 0 ? (packedItems / totalItems) : 0.0;
    final percentage = (progress * 100).toInt();

    final dateRangeFormatted =
        '${DateFormat('dd MMM').format(trip.startDate)} - ${DateFormat('dd MMM yyyy').format(trip.endDate)}';

    final daysUntil = trip.daysUntilDeparture;
    String countdownLabel;
    if (daysUntil < 0) {
      countdownLabel = 'En curso';
    } else if (daysUntil == 0) {
      countdownLabel = '¡Sale hoy!';
    } else if (daysUntil == 1) {
      countdownLabel = 'Sale mañana';
    } else {
      countdownLabel = 'Sale en $daysUntil días';
    }

    final imageUrl = DestinationImageHelper.getImageUrlForDestination(trip.destination);

    return TactilePressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Destination Image with smooth network loading and fallback
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.burgundyBase,
                        isDark ? AppColors.darkCard : AppColors.burgundyDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.flight_takeoff_rounded,
                      size: 48,
                      color: AppColors.goldFoil.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: isDark ? AppColors.darkElevated : AppColors.parchmentElevated,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldFoil),
                  ),
                );
              },
            ),

            // Deep gradient overlay for guaranteed text legibility (WCAG AA)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Banner Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Countdown Pill & Transport Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldFoil.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.textDarkPrimary),
                            const SizedBox(width: 5),
                            Text(
                              countdownLabel,
                              style: AppTypography.caption(color: AppColors.textDarkPrimary, medium: true).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),

                  // Bottom Content: Destination, Dates, Packing Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.isMultiDestination ? trip.routeDisplay : trip.destination,
                        style: AppTypography.subheadSerif(color: Colors.white).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 5),
                          Text(
                            dateRangeFormatted,
                            style: AppTypography.caption(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.luggage_rounded, size: 13, color: AppColors.goldFoilLight),
                          const SizedBox(width: 4),
                          Text(
                            '$packedItems/$totalItems empacados ($percentage%)',
                            style: AppTypography.caption(color: AppColors.goldFoilLight, medium: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Animated Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progress),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) {
                            return LinearProgressIndicator(
                              value: val,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage == 100 ? AppColors.stampEmeraldLight : AppColors.goldFoil,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
