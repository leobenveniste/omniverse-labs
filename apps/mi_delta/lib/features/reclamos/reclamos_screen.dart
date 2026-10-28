import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/reclamo_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/civic_fixed_header.dart';
import 'new_reclamo_sheet.dart';

class ReclamosScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onAvatarTap;

  const ReclamosScreen({
    super.key,
    this.scrollController,
    this.onAvatarTap,
  });

  @override
  ConsumerState<ReclamosScreen> createState() => _ReclamosScreenState();
}

class _ReclamosScreenState extends ConsumerState<ReclamosScreen> {
  // 0: Mis Reportes, 1: Mapa Barrial, 2: Nuevos y Resueltos
  int _activeFilter = 0;
  int _likeCountBache = 24;
  bool _likedBache = false;
  int _likeCountSemaforo = 12;
  bool _likedSemaforo = false;

  @override
  Widget build(BuildContext context) {
    final reclamos = ref.watch(reclamosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: CivicFixedHeader(
        title: 'Reportes Urbanos',
        onAvatarTap: widget.onAvatarTap,
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Filter Switcher
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterButton(
                        index: 0,
                        label: 'Mis reportes',
                        icon: Icons.person_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton(
                        index: 1,
                        label: 'Mapa',
                        icon: Icons.map_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterButton(
                        index: 2,
                        label: 'Resueltos',
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tarjeta de Nuevo Reporte
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF022448),
                        Color(0xFF1E3A5F),
                        Color(0xFF022448),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Detectaste un incidente?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Express Button
                      InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          NewReclamoSheet.show(context);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.photo_camera_rounded, color: AppColors.secondary, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Reporte Express con IA',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Foto + detección automática + GPS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Preset Buttons
                      const Text(
                        'O SELECCIONÁ LA CATEGORÍA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryFixedDim,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCategoryPreset(
                            icon: Icons.lightbulb_outline_rounded,
                            label: 'Luminaria',
                            bgIconColor: const Color(0x33F59E0B),
                            iconColor: const Color(0xFFFBBF24),
                            category: 'Luminarias y Alumbrado',
                          ),
                          _buildCategoryPreset(
                            icon: Icons.construction_rounded,
                            label: 'Bache',
                            bgIconColor: const Color(0x33F97316),
                            iconColor: const Color(0xFFFB923C),
                            category: 'Bacheo y Pavimento',
                          ),
                          _buildCategoryPreset(
                            icon: Icons.delete_sweep_rounded,
                            label: 'Basura',
                            bgIconColor: const Color(0x3310B981),
                            iconColor: const Color(0xFF34D399),
                            category: 'Residuos y Microbasurales',
                          ),
                          _buildCategoryPreset(
                            icon: Icons.park_rounded,
                            label: 'Poda',
                            bgIconColor: const Color(0x3322C55E),
                            iconColor: const Color(0xFF4ADE80),
                            category: 'Poda y Arbolado',
                          ),
                          _buildCategoryPreset(
                            icon: Icons.traffic_rounded,
                            label: 'Semáforo',
                            bgIconColor: const Color(0x33F43F5E),
                            iconColor: const Color(0xFFFB7185),
                            category: 'Semáforos y Tránsito',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content according to selected filter
            if (_activeFilter == 0) ...[
              // Mis Reportes List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tus Reclamos en Gestión',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                      ),
                      Text(
                        'Total: ${reclamos.length}',
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = reclamos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: _buildReclamoCard(item),
                    );
                  },
                  childCount: reclamos.length,
                ),
              ),
            ] else if (_activeFilter == 1) ...[
              // Mapa Barrial View
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Mapa de Incidencias en Tiempo Real',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Altos del Delta',
                            style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Stack(
                          children: [
                            // Simulated Map Background Grid
                            Center(
                              child: Icon(
                                Icons.map_outlined,
                                size: 120,
                                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            // Map Pins
                            Positioned(
                              top: 40,
                              left: 60,
                              child: _buildMapPin(
                                label: 'Bache reparado',
                                color: AppColors.secondaryEmerald,
                                icon: Icons.check_circle_rounded,
                              ),
                            ),
                            Positioned(
                              top: 100,
                              right: 70,
                              child: _buildMapPin(
                                label: 'Semáforo en obra',
                                color: AppColors.primary,
                                icon: Icons.engineering_rounded,
                              ),
                            ),
                            Positioned(
                              bottom: 40,
                              left: 110,
                              child: _buildMapPin(
                                label: 'Luminaria pendiente',
                                color: const Color(0xFFF59E0B),
                                icon: Icons.lightbulb_rounded,
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMapLegend(AppColors.secondaryEmerald, 'Resueltos (14)'),
                                    _buildMapLegend(AppColors.primary, 'En Cuadrilla (6)'),
                                    _buildMapLegend(const Color(0xFFF59E0B), 'Ingresados (3)'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Community Activity Feed (Nuevos y Resueltos)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.dynamic_feed_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Actividad Vecinal • Hoy',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Text('Barrio Norte', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),

              // Feed Item 1: Bache reparado Before/After
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Bache reparado',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      'Calle Belgrano 450',
                                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Resuelto en 48hs',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Before / After comparative blocks
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF64748B),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  children: [
                                    const Center(
                                      child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 36),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Antes',
                                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  children: [
                                    const Center(
                                      child: Icon(Icons.done_all_rounded, color: AppColors.secondaryFixed, size: 36),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryEmerald,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Reparado',
                                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Cuadrilla de Obras Viales finalizó el reasfaltado y sellado técnico. Tránsito reabierto con total normalidad.',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _likedBache = !_likedBache;
                                  _likeCountBache += _likedBache ? 1 : -1;
                                });
                              },
                              icon: Icon(
                                Icons.thumb_up_rounded,
                                size: 14,
                                color: _likedBache ? Colors.white : AppColors.secondary,
                              ),
                              label: Text(
                                'Agradecer ($_likeCountBache)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _likedBache ? Colors.white : AppColors.primary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _likedBache ? AppColors.secondary : AppColors.surfaceContainerLow,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                            const Text('Hace 2 horas', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Feed Item 2: Semáforo In-Progress
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.traffic_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Sincronización Semáforo',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                                    ),
                                    Text(
                                      'Av. Cazón y Dique Luján',
                                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'En Cuadrilla',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Personal técnico de electromecánica reemplazando plaqueta controladora de onda verde.',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _likedSemaforo = !_likedSemaforo;
                                  _likeCountSemaforo += _likedSemaforo ? 1 : -1;
                                });
                              },
                              icon: Icon(
                                Icons.thumb_up_rounded,
                                size: 14,
                                color: _likedSemaforo ? Colors.white : AppColors.secondary,
                              ),
                              label: Text(
                                'Agradecer ($_likeCountSemaforo)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _likedSemaforo ? Colors.white : AppColors.primary,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _likedSemaforo ? AppColors.secondary : AppColors.surfaceContainerLow,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                            const Text('Hace 4 horas', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(
              child: SizedBox(height: 96),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _activeFilter == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = index);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPreset({
    required IconData icon,
    required String label,
    required Color bgIconColor,
    required Color iconColor,
    required String category,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        NewReclamoSheet.show(context, initialCategory: category);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgIconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.surfaceBright,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReclamoCard(ReclamoModel item) {
    Color statusColor = const Color(0xFFF59E0B);
    String statusText = item.statusLabel;
    switch (item.status) {
      case ReclamoStatus.recibido:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Ingresado';
        break;
      case ReclamoStatus.enRevision:
        statusColor = AppColors.primaryContainer;
        statusText = 'En Revisión';
        break;
      case ReclamoStatus.enCuadrilla:
        statusColor = AppColors.primary;
        statusText = 'En Cuadrilla';
        break;
      case ReclamoStatus.resuelto:
        statusColor = AppColors.secondaryEmerald;
        statusText = 'Resuelto';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.status == ReclamoStatus.resuelto ? Icons.check_circle_rounded : Icons.report_problem_outlined,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${item.id.length > 5 ? item.id.substring(item.id.length - 5) : item.id}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.address}, ${item.locality}',
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin({required String label, required Color color, required IconData icon}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
        Icon(Icons.location_on, size: 24, color: color),
      ],
    );
  }

  Widget _buildMapLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
