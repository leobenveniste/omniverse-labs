import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/guide/guide_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/country_helper.dart';
import '../../core/widgets/app_header_title.dart';
import '../../core/widgets/first_use_guide_card.dart';
import '../../core/widgets/tactile_pressable.dart';
import '../../core/widgets/upcoming_trip_banner.dart';
import '../../repositories/storage_repository.dart';
import '../packing/packing_studio_screen.dart';
import '../pro/pro_paywall_modal.dart';
import '../trips/create_trip_dialog.dart';
import 'stamp_album_screen.dart';

class PassportViewScreen extends StatelessWidget {
  final StorageRepository storage;
  final GuideController guideController;

  const PassportViewScreen({
    super.key,
    required this.storage,
    required this.guideController,
  });

  void _showEditProfileDialog(BuildContext context) {
    final t = AppLocalizations.of(context);
    final profile = storage.profile;
    final nameController = TextEditingController(text: profile.fullName);
    final natController = TextEditingController(text: profile.nationality);
    final numController = TextEditingController(text: profile.passportNumber);
    String selectedEmoji = profile.avatarIcon;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(t.t('passport_holder')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['🧑‍✈️', '👩‍✈️', '🧳', '🌍', '✈️', '🧭'].map((emoji) {
                    final isSelected = selectedEmoji == emoji;
                    return InkWell(
                      onTap: () {
                        selectedEmoji = emoji;
                        (ctx as Element).markNeedsBuild();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.goldFoil.withValues(alpha: 0.25) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.goldFoil : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: t.t('passport_fullname'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: natController,
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: t.t('passport_nationality'),
                    border: const OutlineInputBorder(),
                    counterText: '',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CountryHelper.buildFlag(natController.text, width: 22, height: 15),
                    ),
                  ),
                  onChanged: (_) => (ctx as Element).markNeedsBuild(),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: ['ARG', 'ESP', 'USA', 'ITA', 'FRA', 'DEU', 'BRA', 'MEX', 'CHL', 'URY', 'COL'].map((c) {
                    final isSel = natController.text.toUpperCase() == c;
                    return InkWell(
                      onTap: () {
                        natController.text = c;
                        (ctx as Element).markNeedsBuild();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.goldFoil : AppColors.goldFoil.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.black : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: t.t('passport_number'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.t('btn_cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = profile.copyWith(
                  avatarIcon: selectedEmoji,
                  fullName: nameController.text.trim().isEmpty ? profile.fullName : nameController.text.trim().toUpperCase(),
                  nationality: natController.text.trim().isEmpty ? profile.nationality : natController.text.trim().toUpperCase(),
                  passportNumber: numController.text.trim().isEmpty ? profile.passportNumber : numController.text.trim().toUpperCase(),
                );
                storage.updateProfile(updated);
                Navigator.of(ctx).pop();
              },
              child: Text(t.t('btn_save')),
            ),
          ],
        );
      },
    );
  }

  void _handleCreateTrip(BuildContext context) async {
    if (!storage.canCreateTrip) {
      ProPaywallModal.show(
        context,
        storage,
        customReason: storage.tripCreationBlockReason,
      );
      return;
    }

    final newTrip = await showDialog(
      context: context,
      builder: (_) => CreateTripDialog(storage: storage),
    );

    if (newTrip != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Viaje a ${newTrip.destination} programado con éxito!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profile = storage.profile;
    final upcomingTrips = storage.upcomingTrips;
    final totalTrips = storage.trips.length;
    final totalStamps = storage.stamps.length;

    final totalItems = storage.items.length;
    final packedItems = storage.items.where((i) => i.isPacked).length;
    final packedRate = totalItems > 0 ? ((packedItems / totalItems) * 100).toInt() : 100;

    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;
    final textPrimary = isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;

    final expiryFormatted = DateFormat('dd MMM yyyy').format(profile.expiryDate).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: AppHeaderTitle(
          title: t.t('passport_title'),
          isPro: storage.isPro,
        ),
        actions: [
          if (!storage.isPro)
            IconButton(
              icon: const Text('👑', style: TextStyle(fontSize: 18)),
              tooltip: 'EmpacArte PRO',
              onPressed: () => ProPaywallModal.show(context, storage),
            ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: t.t('passport_holder'),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (guideController.shouldShowGuide(GuideController.passportGuide))
              FirstUseGuideCard(
                icon: Icons.badge_rounded,
                title: t.locale.languageCode == 'es' ? 'Tu Pasaporte de Viajero' : 'Your Traveler Passport',
                description: t.locale.languageCode == 'es'
                    ? 'Este es tu documento biométrico en EmpacArte. Mantené actualizados tus datos y consultá tus estadísticas de viaje.'
                    : 'This is your biometric travel document in EmpacArte. Keep your travel details updated and track your packing stats.',
                bulletPoints: t.locale.languageCode == 'es'
                    ? [
                        'Tocá el icono del lápiz arriba a la derecha para personalizar tu nombre, nacionalidad y emoji.',
                        'Tus viajes organizados y sellos obtenidos se registran automáticamente aquí.',
                        'Debajo encontrarás tus próximos viajes con acceso rápido a sus valijas.',
                      ]
                    : [
                        'Tap the pencil icon on the top right to customize your name, country and emoji.',
                        'Your planned journeys and earned stamps are tracked right here.',
                        'Below you will find your upcoming trips with one-tap packing access.',
                      ],
                onDismiss: () => guideController.markGuideSeen(GuideController.passportGuide),
              ),

            // --- PASSPORT BIOMETRIC CARD ---
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.goldFoil.withValues(alpha: 0.5) : AppColors.burgundyBase.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Passport Top Burgundy Band
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18.5)),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.burgundyBase, AppColors.burgundyDark]
                            : [AppColors.burgundyBase, AppColors.burgundyDeep],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.travel_explore_rounded, color: AppColors.goldFoilLight, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'PASSPORT • PASAPORTE',
                          style: AppTypography.monoCaption(color: AppColors.goldFoilLight, medium: true),
                        ),
                        const Spacer(),
                        if (storage.isPro)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.goldFoil.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '👑 PRO',
                              style: AppTypography.caption(
                                color: AppColors.textDarkPrimary,
                                medium: true,
                              ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        else if (profile.isExpiringSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.stampCrimsonLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.t('passport_status_expiring'),
                              style: AppTypography.caption(
                                color: Colors.white,
                                medium: true,
                              ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Photo & Primary Fields
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Passport Photo Frame
                        Container(
                          width: 84,
                          height: 106,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkElevated : AppColors.parchmentElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: goldAccent, width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(profile.avatarIcon, style: const TextStyle(fontSize: 38)),
                              const SizedBox(height: 4),
                              Text(
                                profile.nationality,
                                style: AppTypography.monoCaption(color: goldAccent, medium: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Field Grid
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PassportField(
                                label: t.t('passport_fullname'),
                                value: profile.fullName,
                                isPrimary: true,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PassportField(
                                      label: t.t('passport_nationality'),
                                      value: t.locale.languageCode == 'es'
                                          ? CountryHelper.findCountry(profile.nationality).nameEs
                                          : CountryHelper.findCountry(profile.nationality).nameEn,
                                      leading: CountryHelper.buildFlag(profile.nationality, width: 18, height: 12),
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                  Expanded(
                                    child: _PassportField(
                                      label: t.t('passport_number'),
                                      value: profile.passportNumber,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _PassportField(
                                label: t.t('passport_expiry'),
                                value: expiryFormatted,
                                textPrimary: profile.isExpiringSoon ? AppColors.stampCrimsonLight : textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Perforated Line
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomPaint(
                      painter: _PerforatedDividerPainter(
                        color: borderColor,
                      ),
                      size: const Size(double.infinity, 1),
                    ),
                  ),

                  // Machine Readable Zone (MRZ)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.parchmentBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.mrzLine1,
                          style: AppTypography.monoCaption(color: textPrimary, medium: true).copyWith(
                            letterSpacing: 2,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.mrzLine2,
                          style: AppTypography.monoCaption(color: textPrimary, medium: true).copyWith(
                            letterSpacing: 2,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- TRAVEL STATS ROW ---
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.flight_takeoff_rounded,
                    title: t.t('passport_stats_trips'),
                    value: '$totalTrips',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.approval_rounded,
                    title: t.t('passport_stats_stamps'),
                    value: '$totalStamps',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline_rounded,
                    title: t.t('passport_stats_packed'),
                    value: '$packedRate%',
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- PRÓXIMOS VIAJES (UPCOMING TRIPS BANNERS) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 20, color: goldAccent),
                    const SizedBox(width: 8),
                    Text(
                      t.locale.languageCode == 'es' ? 'Próximos Viajes' : 'Upcoming Journeys',
                      style: AppTypography.subheadSerif(color: textPrimary).copyWith(fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: goldAccent,
                  tooltip: t.t('trips_new_trip'),
                  onPressed: () => _handleCreateTrip(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (upcomingTrips.isNotEmpty)
              ...upcomingTrips.map((trip) {
                final tripItems = storage.getItemsForTrip(trip.id);
                final packed = tripItems.where((i) => i.isPacked).length;

                return UpcomingTripBanner(
                  trip: trip,
                  totalItems: tripItems.length,
                  packedItems: packed,
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 350),
                        pageBuilder: (context, animation, secondaryAnimation) => PackingStudioScreen(
                          storage: storage,
                          initialTripId: trip.id,
                          guideController: guideController,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  },
                );
              })
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.airplane_ticket_outlined,
                      size: 48,
                      color: textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.locale.languageCode == 'es' ? '¿A dónde viajamos?' : 'Where to next?',
                      style: AppTypography.subheadSerif(color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.locale.languageCode == 'es'
                          ? 'Planificá tu próximo destino y armá tu valija inteligente según el clima.'
                          : 'Plan your next journey and prepare your smart packing list based on weather.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption(color: textSecondary),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.goldFoil : AppColors.burgundyBase,
                        foregroundColor: isDark ? AppColors.textDarkPrimary : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => _handleCreateTrip(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        t.locale.languageCode == 'es' ? 'Crear Próximo Viaje' : 'Plan Next Trip',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // --- OPEN STAMP ALBUM CTA ---
            TactilePressable(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StampAlbumScreen(
                      storage: storage,
                      guideController: guideController,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkElevated, AppColors.darkCard]
                        : [AppColors.burgundyBase, AppColors.burgundyDeep],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.goldFoil : AppColors.burgundyBase).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldFoil.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.goldFoilLight, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.t('passport_open_album'),
                            style: AppTypography.subheadSerif(color: AppColors.goldFoilLight),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalStamps ${t.t('passport_stats_stamps').toLowerCase()}',
                            style: AppTypography.caption(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.goldFoilLight, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassportField extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Widget? leading;

  const _PassportField({
    required this.label,
    required this.value,
    this.isPrimary = false,
    required this.textPrimary,
    required this.textSecondary,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption(color: textSecondary).copyWith(
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                value,
                style: isPrimary
                    ? AppTypography.subheadSerif(color: textPrimary).copyWith(fontSize: 15)
                    : AppTypography.bodySmall(color: textPrimary, medium: true),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;
    final goldAccent = isDark ? AppColors.goldFoil : AppColors.burgundyBase;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: goldAccent),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.subheadSerif(color: goldAccent).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.caption(color: textSecondary).copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PerforatedDividerPainter extends CustomPainter {
  final Color color;

  _PerforatedDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
