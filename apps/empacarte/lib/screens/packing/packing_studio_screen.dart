import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/guide/guide_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/first_use_guide_card.dart';
import '../../core/widgets/tactile_pressable.dart';
import '../../models/packing_item.dart';
import '../../models/trip.dart';
import '../../repositories/storage_repository.dart';
import '../pro/pro_paywall_modal.dart';
import '../trips/edit_trip_dialog.dart';
import '../trips/itinerary_timeline_modal.dart';
import 'add_item_dialog.dart';

class PackingStudioScreen extends StatefulWidget {
  final StorageRepository storage;
  final String? initialTripId;
  final GuideController guideController;

  const PackingStudioScreen({
    super.key,
    required this.storage,
    this.initialTripId,
    required this.guideController,
  });

  @override
  State<PackingStudioScreen> createState() => _PackingStudioScreenState();
}

class _PackingStudioScreenState extends State<PackingStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedTripId;
  bool _hotelCheckOutMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialTripId != null &&
        widget.storage.trips.any((t) => t.id == widget.initialTripId)) {
      _selectedTripId = widget.initialTripId!;
    } else if (widget.storage.trips.isNotEmpty) {
      _selectedTripId = widget.storage.trips.first.id;
    } else {
      _selectedTripId = '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Trip? get _currentTrip {
    final list = widget.storage.trips.where((t) => t.id == _selectedTripId).toList();
    return list.isNotEmpty ? list.first : null;
  }

  BagCompartment _currentBag() {
    switch (_tabController.index) {
      case 0:
        return BagCompartment.personalItem;
      case 1:
        return BagCompartment.carryOn;
      case 2:
      default:
        return BagCompartment.checked;
    }
  }

  double _getBagLimitKg(Trip trip, BagCompartment bag) {
    switch (bag) {
      case BagCompartment.personalItem:
        return trip.personalItemLimitKg;
      case BagCompartment.carryOn:
        return trip.carryOnLimitKg;
      case BagCompartment.checked:
        return trip.checkedLimitKg;
    }
  }

  void _checkOverallCompletion(Trip trip) {
    final tripItems = widget.storage.getItemsForTrip(trip.id);
    if (tripItems.isNotEmpty && tripItems.every((i) => i.isPacked)) {
      HapticFeedback.heavyImpact();
      widget.storage.addCustomsClearedStamp(trip.id, trip.destination.split(',').first.trim());

      final t = AppLocalizations.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.parchmentCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight,
              width: 2,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.t('stamp_customs_cleared'),
                  style: AppTypography.subheadSerif(
                    color: isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            t.locale.languageCode == 'es'
                ? '¡100% de tu equipaje verificado y empacado! Se ha otorgado un sello consular de Despacho Aduanero a tu pasaporte.'
                : '100% of your luggage is verified & packed! A customs cleared consular seal has been added to your passport album.',
            style: AppTypography.body(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.t('btn_done')),
            ),
          ],
        ),
      );
    }
  }

  void _openAddItem(BuildContext context) async {
    final trip = _currentTrip;
    if (trip == null) return;

    final newItem = await showDialog<PackingItem>(
      context: context,
      builder: (_) => AddItemDialog(
        tripId: trip.id,
        initialBag: _currentBag(),
      ),
    );

    if (newItem != null) {
      await widget.storage.addPackingItem(newItem);
      if (newItem.isAlwaysPack) {
        await widget.storage.toggleAlwaysPack(newItem.name, true);
      }
      _checkOverallCompletion(trip);
    }
  }

  List<String> _detectAirportSecurityIssues(List<PackingItem> items) {
    final issues = <String>[];
    for (final item in items) {
      final name = item.name.toLowerCase();
      // Lithium battery / powerbank in checked luggage
      if (item.compartment == BagCompartment.checked &&
          (name.contains('powerbank') ||
              name.contains('batería') ||
              name.contains('battery') ||
              name.contains('lithium'))) {
        issues.add(
          '⚠️ "${item.name}" está en Bodega: Las baterías de litio están prohibidas en bodega por seguridad aérea (IATA). Muévela a Mochila de mano.',
        );
      }
    }
    return issues;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpanish = t.locale.languageCode == 'es';
    final isPro = widget.storage.isPro;

    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;

    final trip = _currentTrip;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.t('pack_title'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight_takeoff_rounded, size: 56, color: textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                isSpanish ? 'No hay viajes activos seleccionados' : 'No active trip selected',
                style: AppTypography.subheadSerif(color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final allItems = widget.storage.getItemsForTrip(trip.id);
    final securityIssues = isPro ? _detectAirportSecurityIssues(allItems) : <String>[];

    // Filter for Hotel Departure Reverse Packing Mode
    List<PackingItem> displayItems;
    if (_hotelCheckOutMode) {
      displayItems = allItems.where((i) {
        final name = i.name.toLowerCase();
        return name.contains('cargador') ||
            name.contains('charger') ||
            name.contains('pasaporte') ||
            name.contains('passport') ||
            name.contains('cepillo') ||
            name.contains('medicación') ||
            name.contains('llave') ||
            name.contains('adaptador') ||
            i.category == PackingCategory.documents ||
            i.category == PackingCategory.tech;
      }).toList();
    } else {
      displayItems = allItems;
    }

    final packedCount = displayItems.where((i) => i.isPacked).length;
    final overallProgress = displayItems.isNotEmpty ? packedCount / displayItems.length : 0.0;
    final overallPercentage = (overallProgress * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.isMultiDestination ? trip.routeDisplay : trip.destination,
              style: AppTypography.subheadSerif(color: isDark ? AppColors.goldFoil : AppColors.burgundyBase).copyWith(
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$packedCount/${displayItems.length} empacados ($overallPercentage%)',
              style: AppTypography.caption(color: textSecondary).copyWith(fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Edit trip button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isSpanish ? 'Editar Viaje' : 'Edit Trip',
            onPressed: () async {
              await EditTripDialog.show(
                context,
                trip: trip,
                storage: widget.storage,
              );
              setState(() {});
            },
          ),
          // Itinerary modal button
          IconButton(
            icon: const Icon(Icons.alt_route_rounded),
            tooltip: isSpanish ? 'Itinerario y Check-in/out' : 'Itinerary & Check-in/out',
            onPressed: () => ItineraryTimelineModal.show(
              context,
              trip: trip,
              storage: widget.storage,
            ),
          ),
          // Hotel Check-out Reverse Packing toggle
          IconButton(
            icon: Icon(
              _hotelCheckOutMode ? Icons.hotel_rounded : Icons.hotel_outlined,
              color: _hotelCheckOutMode ? AppColors.goldFoil : null,
            ),
            tooltip: isSpanish ? 'Modo Salida del Hotel' : 'Hotel Check-out Mode',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _hotelCheckOutMode = !_hotelCheckOutMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _hotelCheckOutMode
                        ? (isSpanish
                            ? '🏨 Modo Check-out activado: Filtrando cargadores, pasaporte y artículos críticos.'
                            : '🏨 Hotel Departure Mode: Showing chargers, passport & essential items.')
                        : (isSpanish ? 'Mostrando equipaje completo.' : 'Showing full luggage list.'),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          if (!isPro)
            IconButton(
              icon: const Text('👑', style: TextStyle(fontSize: 18)),
              tooltip: 'EmpacArte PRO',
              onPressed: () => ProPaywallModal.show(context, widget.storage),
            ),
          // Add Item Button in Header
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: t.t('add_item_title'),
            onPressed: () => _openAddItem(context),
          ),
        ],
        bottom: isPro && !_hotelCheckOutMode
            ? TabBar(
                controller: _tabController,
                indicatorColor: goldAccent,
                labelColor: goldAccent,
                unselectedLabelColor: textSecondary,
                tabs: [
                  Tab(icon: const Icon(Icons.backpack_outlined), text: t.t('pack_bag_personal')),
                  Tab(icon: const Icon(Icons.luggage_outlined), text: t.t('pack_bag_carryon')),
                  Tab(icon: const Icon(Icons.business_center_outlined), text: t.t('pack_bag_checked')),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // PRO Upsell banner for Free Users
          if (!isPro)
            TactilePressable(
              onTap: () => ProPaywallModal.show(context, widget.storage),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.goldFoil.withValues(alpha: 0.15),
                      (isDark ? AppColors.goldFoilDark : AppColors.burgundyBase).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldFoil.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSpanish
                            ? 'Desbloqueá PRO para dividir en Mochila, Carry-on y Bodega con balanza automática.'
                            : 'Unlock PRO to organize into Backpack, Carry-on & Checked bags with weight scale.',
                        style: AppTypography.caption(color: textPrimary, medium: true),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: goldAccent),
                  ],
                ),
              ),
            ),

          // Airport Security Alert Banner (PRO feature)
          if (securityIssues.isNotEmpty)
            ...securityIssues.map((issue) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.stampCrimsonLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.stampCrimsonLight.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.stampCrimsonLight, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue,
                        style: AppTypography.caption(color: textPrimary, medium: true),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // First use guide
          if (widget.guideController.shouldShowGuide(GuideController.packingGuide))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: FirstUseGuideCard(
                icon: Icons.luggage_rounded,
                title: isSpanish ? 'Tu Estudio de Empaque' : 'Packing Studio',
                description: isSpanish
                    ? 'Chequeá tus ítems mientras armás la valija y controlá el peso para no pagar cargos extra.'
                    : 'Check items as you pack and monitor weights to avoid airline overweight fees.',
                bulletPoints: isSpanish
                    ? [
                        'Tocá cualquier ítem para marcarlo con respuesta háptica.',
                        'Deslizá un ítem hacia la izquierda para eliminarlo.',
                        'Alcanzá el 100% para obtener tu sello de Despacho Aduanero.',
                      ]
                    : [
                        'Tap any item to check it off with tactile feedback.',
                        'Swipe left on any item to delete it from the list.',
                        'Reach 100% to earn your Customs Cleared seal.',
                      ],
                onDismiss: () => widget.guideController.markGuideSeen(GuideController.packingGuide),
              ),
            ),

          // Main List View
          Expanded(
            child: isPro && !_hotelCheckOutMode
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBagCompartmentList(trip, BagCompartment.personalItem, isDark, textPrimary, textSecondary),
                      _buildBagCompartmentList(trip, BagCompartment.carryOn, isDark, textPrimary, textSecondary),
                      _buildBagCompartmentList(trip, BagCompartment.checked, isDark, textPrimary, textSecondary),
                    ],
                  )
                : _buildUnifiedItemList(trip, displayItems, isDark, textPrimary, textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedItemList(
    Trip trip,
    List<PackingItem> items,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No hay ítems en esta lista',
          style: AppTypography.body(color: textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, idx) {
        if (idx == items.length) {
          return const SizedBox(height: 70); // Space for FAB
        }
        final item = items[idx];
        return _buildItemRow(trip, item, isDark, textPrimary, textSecondary);
      },
    );
  }

  Widget _buildBagCompartmentList(
    Trip trip,
    BagCompartment compartment,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final bagItems = widget.storage.getItemsForTrip(trip.id).where((i) => i.compartment == compartment).toList();
    final bagWeight = bagItems.fold(0.0, (acc, i) => acc + i.weightKg);
    final limitKg = _getBagLimitKg(trip, compartment);
    final weightProgress = (bagWeight / limitKg).clamp(0.0, 1.0);
    final isOverweight = bagWeight > limitKg;

    return Column(
      children: [
        // Luggage Weight Gauge Meter
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverweight
                  ? AppColors.stampCrimsonLight
                  : (isDark ? AppColors.darkBorder : AppColors.parchmentBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.scale_rounded, size: 16, color: isOverweight ? AppColors.stampCrimsonLight : textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${bagWeight.toStringAsFixed(1)} kg / ${limitKg.toStringAsFixed(1)} kg',
                        style: AppTypography.subheadSans(
                          color: isOverweight ? AppColors.stampCrimsonLight : textPrimary,
                          bold: true,
                        ),
                      ),
                    ],
                  ),
                  if (isOverweight)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.stampCrimsonLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'EXCESO DE PESO',
                        style: AppTypography.caption(color: AppColors.stampCrimsonLight, medium: true),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: weightProgress),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, val, _) {
                    return LinearProgressIndicator(
                      value: val,
                      minHeight: 6,
                      backgroundColor: textSecondary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverweight ? AppColors.stampCrimsonLight : AppColors.stampEmeraldLight,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: bagItems.isEmpty
              ? Center(
                  child: Text(
                    'No hay ítems en este bulto',
                    style: AppTypography.body(color: textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bagItems.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == bagItems.length) {
                      return const SizedBox(height: 70);
                    }
                    final item = bagItems[idx];
                    return _buildItemRow(trip, item, isDark, textPrimary, textSecondary);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItemRow(
    Trip trip,
    PackingItem item,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.stampCrimsonLight,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        final deletedItem = item;
        widget.storage.deletePackingItem(deletedItem.id);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_sweep_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSpanish
                        ? 'Se eliminó "${deletedItem.name}"'
                        : 'Removed "${deletedItem.name}"',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: isSpanish ? 'Deshacer' : 'Undo',
              textColor: AppColors.goldFoil,
              onPressed: () async {
                HapticFeedback.lightImpact();
                await widget.storage.addPackingItem(deletedItem);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.parchmentCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isPacked
                ? AppColors.stampEmeraldLight.withValues(alpha: 0.5)
                : (isDark ? AppColors.darkBorder : AppColors.parchmentBorder),
          ),
        ),
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.storage.toggleItemPacked(item.id);
            _checkOverallCompletion(trip);
          },
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.isPacked ? AppColors.stampEmeraldLight : Colors.transparent,
              border: Border.all(
                color: item.isPacked ? AppColors.stampEmeraldLight : textSecondary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: item.isPacked
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
          title: Text(
            item.name,
            style: AppTypography.bodySmall(
              color: item.isPacked ? textSecondary : textPrimary,
              medium: true,
            ).copyWith(
              decoration: item.isPacked ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${item.quantity} un. • ${item.weightKg.toStringAsFixed(2)} kg',
            style: AppTypography.caption(color: textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isAlwaysPack)
                const Tooltip(
                  message: 'Siempre llevo esto',
                  child: Icon(Icons.push_pin_rounded, size: 16, color: AppColors.goldFoil),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: textSecondary.withValues(alpha: 0.6),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.storage.deletePackingItem(item.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
