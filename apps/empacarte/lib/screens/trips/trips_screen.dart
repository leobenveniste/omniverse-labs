import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/guide/guide_controller.dart';
import '../../core/widgets/app_header_title.dart';
import '../../core/widgets/boarding_pass_card.dart';
import '../../core/widgets/first_use_guide_card.dart';
import '../../models/trip.dart';
import '../../repositories/storage_repository.dart';
import '../packing/packing_studio_screen.dart';
import '../pro/pro_paywall_modal.dart';
import 'create_trip_dialog.dart';
import 'edit_trip_dialog.dart';
import 'itinerary_timeline_modal.dart';
import 'new_trip_screen.dart';

class TripsScreen extends StatefulWidget {
  final StorageRepository storage;
  final GuideController guideController;

  const TripsScreen({
    super.key,
    required this.storage,
    required this.guideController,
  });

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  Future<void> _openCreateTrip() async {
    if (!widget.storage.canCreateTrip) {
      ProPaywallModal.show(
        context,
        widget.storage,
        customReason: widget.storage.tripCreationBlockReason,
      );
      return;
    }

    final newTrip = await Navigator.of(context).push<Trip>(
      MaterialPageRoute(
        builder: (_) => NewTripScreen(storage: widget.storage),
      ),
    );

    if (newTrip != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarjeta de embarque emitida para ${newTrip.destination}!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _confirmDeleteTrip(Trip trip) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.parchmentCard,
        title: Text(trip.destination, style: AppTypography.subheadSerif(color: isDark ? AppColors.goldFoil : AppColors.burgundyBase)),
        content: Text(t.t('trips_delete_confirm'), style: AppTypography.body(color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.t('btn_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.stampCrimsonLight,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.storage.deleteTrip(trip.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trips = widget.storage.trips;

    final upcomingTrips = trips.where((tr) => !tr.isPast).toList();
    final pastTrips = trips.where((tr) => tr.isPast).toList();

    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return Scaffold(
      appBar: AppBar(
        title: AppHeaderTitle(
          title: t.t('trips_title'),
          isPro: widget.storage.isPro,
        ),
        actions: [
          if (!widget.storage.isPro)
            IconButton(
              icon: const Text('👑', style: TextStyle(fontSize: 18)),
              tooltip: 'EmpacArte PRO',
              onPressed: () => ProPaywallModal.show(context, widget.storage),
            ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: t.t('trips_new_trip'),
            onPressed: _openCreateTrip,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.guideController.shouldShowGuide(GuideController.tripsGuide))
            FirstUseGuideCard(
              icon: Icons.airplane_ticket_rounded,
              title: t.locale.languageCode == 'es' ? 'Tus Tarjetas de Embarque' : 'Your Boarding Passes',
              description: t.locale.languageCode == 'es'
                  ? 'Gestioná tus próximos viajes con tarjetas de embarque perforadas e itinerarios visuales.'
                  : 'Manage your upcoming trips with tactile boarding passes and visual itineraries.',
              bulletPoints: t.locale.languageCode == 'es'
                  ? [
                      'Tocá el botón (+) para emitir un nuevo pase con destino, fechas y transporte.',
                      'Al crear un viaje se genera automáticamente una lista inteligente de equipaje.',
                      'Tocá cualquier tarjeta para ingresar al Estudio de Empaque de ese viaje.',
                    ]
                  : [
                      'Tap (+) to issue a new boarding pass with destination, dates and transport.',
                      'Creating a trip automatically generates a personalized smart packing list.',
                      'Tap any boarding pass to enter its dedicated Packing Studio.',
                    ],
              onDismiss: () => widget.guideController.markGuideSeen(GuideController.tripsGuide),
            ),
          if (trips.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 56, color: textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    t.t('trips_empty'),
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: textSecondary),
                  ),
                ],
              ),
            )
          else ...[
            if (upcomingTrips.isNotEmpty) ...[
              Text(
                t.t('trips_upcoming'),
                style: AppTypography.subheadSerif(color: isDark ? AppColors.goldFoil : AppColors.burgundyBase),
              ),
              const SizedBox(height: 12),
              ...upcomingTrips.map((trip) {
                final items = widget.storage.getItemsForTrip(trip.id);
                final packed = items.where((i) => i.isPacked).length;

                return BoardingPassCard(
                  trip: trip,
                  totalItems: items.length,
                  packedItems: packed,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PackingStudioScreen(
                          storage: widget.storage,
                          initialTripId: trip.id,
                          guideController: widget.guideController,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _confirmDeleteTrip(trip),
                  onItineraryTap: () => ItineraryTimelineModal.show(
                    context,
                    trip: trip,
                    storage: widget.storage,
                  ),
                  onEditTap: () => EditTripDialog.show(
                    context,
                    trip: trip,
                    storage: widget.storage,
                  ),
                );
              }),
            ],
            if (pastTrips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                t.t('trips_past'),
                style: AppTypography.subheadSerif(color: textSecondary),
              ),
              const SizedBox(height: 12),
              ...pastTrips.map((trip) {
                final items = widget.storage.getItemsForTrip(trip.id);
                final packed = items.where((i) => i.isPacked).length;

                return BoardingPassCard(
                  trip: trip,
                  totalItems: items.length,
                  packedItems: packed,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PackingStudioScreen(
                          storage: widget.storage,
                          initialTripId: trip.id,
                          guideController: widget.guideController,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _confirmDeleteTrip(trip),
                  onItineraryTap: () => ItineraryTimelineModal.show(
                    context,
                    trip: trip,
                    storage: widget.storage,
                  ),
                  onEditTap: () => EditTripDialog.show(
                    context,
                    trip: trip,
                    storage: widget.storage,
                  ),
                );
              }),
            ],
            const SizedBox(height: 60), // Room for FAB
          ],
        ],
      ),
    );
  }
}
