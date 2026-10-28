import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/guide/guide_controller.dart';
import '../../core/widgets/first_use_guide_card.dart';
import '../../core/widgets/passport_stamp_painter.dart';
import '../../core/widgets/tactile_pressable.dart';
import '../../models/collectible_stamp.dart';
import '../../repositories/storage_repository.dart';

class StampAlbumScreen extends StatefulWidget {
  final StorageRepository storage;
  final GuideController guideController;

  const StampAlbumScreen({
    super.key,
    required this.storage,
    required this.guideController,
  });

  @override
  State<StampAlbumScreen> createState() => _StampAlbumScreenState();
}

class _StampAlbumScreenState extends State<StampAlbumScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Entry, 2: Customs Cleared

  List<CollectibleStamp> _filteredStamps(List<CollectibleStamp> all) {
    if (_selectedFilterIndex == 1) {
      return all.where((s) => s.type == StampType.entry).toList();
    } else if (_selectedFilterIndex == 2) {
      return all.where((s) => s.type == StampType.customsCleared).toList();
    }
    return all;
  }

  void _showStampDetail(BuildContext context, CollectibleStamp stamp) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMMM yyyy').format(stamp.date);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.parchmentCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PassportStampWidget(stamp: stamp, size: 160),
              const SizedBox(height: 16),
              Text(
                stamp.cityName,
                style: AppTypography.subheadSerif(color: isDark ? AppColors.goldFoil : AppColors.burgundyBase),
              ),
              const SizedBox(height: 4),
              Text(
                '${stamp.stationCode} • $dateStr',
                style: AppTypography.monoCaption(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkElevated : AppColors.parchmentElevated),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.parchmentBorder,
                  ),
                ),
                child: Text(
                  stamp.type == StampType.customsCleared
                      ? t.t('stamp_customs_cleared')
                      : t.t('stamp_arrival'),
                  style: AppTypography.caption(
                    color: stamp.type == StampType.customsCleared
                        ? (isDark ? AppColors.stampEmeraldDark : AppColors.stampEmeraldLight)
                        : (isDark ? AppColors.goldFoil : AppColors.burgundyBase),
                    medium: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stamps = _filteredStamps(widget.storage.stamps);

    final borderColor = isDark ? AppColors.darkBorder : AppColors.parchmentBorder;
    final textSecondary = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.parchmentCard;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('stamp_album_title')),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _buildFilterChip(0, 'All (${widget.storage.stamps.length})', isDark),
                const SizedBox(width: 8),
                _buildFilterChip(1, t.t('stamp_arrival'), isDark),
                const SizedBox(width: 8),
                _buildFilterChip(2, t.t('stamp_customs_cleared'), isDark),
              ],
            ),
          ),
          if (widget.guideController.shouldShowGuide(GuideController.albumGuide))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FirstUseGuideCard(
                icon: Icons.menu_book_rounded,
                title: t.locale.languageCode == 'es' ? 'Álbum de Visas y Sellos' : 'Visa Stamps Album',
                description: t.locale.languageCode == 'es'
                    ? 'Acá se coleccionan automáticamente los sellos de tus viajes.'
                    : 'Here you collect stamps earned from your journeys.',
                bulletPoints: t.locale.languageCode == 'es'
                    ? [
                        'Al registrar un viaje obtenés tu sello de entrada con la fecha y código de aeropuerto.',
                        'Al empacar el 100% de tu valija recibís el prestigioso sello verde de Aduana Verificada.',
                        'Tocá cualquier sello para inspeccionar sus detalles consulares.',
                      ]
                    : [
                        'Logging a journey earns an arrival entry stamp with airport code.',
                        'Packing 100% of your luggage unlocks the green Customs Cleared visa seal.',
                        'Tap any stamp to view its consular clearance details.',
                      ],
                onDismiss: () => widget.guideController.markGuideSeen(GuideController.albumGuide),
              ),
            ),
          const Divider(height: 1),

          // Visa Stamp Page Grid
          Expanded(
            child: stamps.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.approval_rounded, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            t.t('stamp_album_empty'),
                            textAlign: TextAlign.center,
                            style: AppTypography.body(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: stamps.length,
                    itemBuilder: (context, index) {
                      final stamp = stamps[index];
                      return TactilePressable(
                        onTap: () => _showStampDetail(context, stamp),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Center(
                            child: PassportStampWidget(stamp: stamp, size: 130),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    final activeColor = isDark ? AppColors.goldFoil : AppColors.burgundyBase;
    final inactiveColor = isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;

    return TactilePressable(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : AppColors.parchmentCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? AppColors.darkBorder : AppColors.parchmentBorder),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            color: isSelected ? activeColor : inactiveColor,
            medium: true,
          ),
        ),
      ),
    );
  }
}
