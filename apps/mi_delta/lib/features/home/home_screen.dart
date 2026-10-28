import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/reclamo_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/civic_fixed_header.dart';
import '../tramites/solicitar_turno_modal.dart';
import '../reclamos/new_reclamo_sheet.dart';
import 'package:stacked_cards_carousel/stacked_cards_carousel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback onNavigateToReclamos;
  final VoidCallback? onNavigateToTramites;
  final VoidCallback? onNavigateToAgenda;
  final VoidCallback? onNavigateToSoyDelta;
  final VoidCallback? onNavigateToCredencial;
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({
    super.key,
    this.scrollController,
    required this.onNavigateToReclamos,
    this.onNavigateToTramites,
    this.onNavigateToAgenda,
    this.onNavigateToSoyDelta,
    this.onNavigateToCredencial,
    this.onNavigateToProfile,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedPollOption = 0;
  bool _isEventRegistered = false;
  int _currentCardIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final reclamos = ref.watch(reclamosProvider);
    final turnos = ref.watch(turnosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeReclamo = reclamos.firstWhere(
      (r) => r.status != ReclamoStatus.resuelto,
      orElse: () => reclamos.first,
    );

    final nextTurno = turnos.isNotEmpty ? turnos.first : null;

    final cards = [
      _buildTurnoCard(nextTurno, isDark),
      _buildReclamoCard(activeReclamo, isDark),
      _buildCredencialCard(user, isDark),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      // Fixed Header across the entire top
      appBar: CivicFixedHeader(
        title: 'Mi Delta',
        onAvatarTap: widget.onNavigateToProfile,
      ),
      body: CustomScrollView(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Greeting & Weather Pill (without 'COMUNIDAD ACTIVA')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '¡Hola, ${user?.name.split(' ').first ?? 'Vecino'}! 👋',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSecondary.withValues(alpha: 0.15)
                          : AppColors.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wb_sunny_rounded, size: 16, color: isDark ? AppColors.darkSecondary : AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          '22°C',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkSecondary : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Redesigned Swipeable Stack of Civic Cards (Turnos & Seguimiento de Reclamos)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stack Header with Title, Dots indicator, and Left/Right navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dashboard_customize_rounded, size: 17, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Gestiones Activas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Dots Indicator
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(cards.length, (i) {
                              final isActive = i == _currentCardIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                width: isActive ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: isActive
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkOnSurfaceMuted : AppColors.outlineVariant).withValues(alpha: 0.6),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 10),
                          // Left Button (<)
                          Semantics(
                            button: true,
                            label: 'Tarjeta anterior',
                            child: Tooltip(
                              message: 'Anterior',
                              child: InkWell(
                                onTap: _currentCardIndex > 0
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _currentCardIndex--);
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentCardIndex > 0
                                        ? (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _currentCardIndex > 0
                                          ? AppColors.cardBorder
                                          : AppColors.cardBorder.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    size: 18,
                                    color: _currentCardIndex > 0
                                        ? AppColors.primary
                                        : AppColors.outlineVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Right Button (>)
                          Semantics(
                            button: true,
                            label: 'Siguiente tarjeta',
                            child: Tooltip(
                              message: 'Siguiente',
                              child: InkWell(
                                onTap: _currentCardIndex < cards.length - 1
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _currentCardIndex++);
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentCardIndex < cards.length - 1
                                        ? (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _currentCardIndex < cards.length - 1
                                          ? AppColors.cardBorder
                                          : AppColors.cardBorder.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: _currentCardIndex < cards.length - 1
                                        ? AppColors.primary
                                        : AppColors.outlineVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stacked Cards Carousel (horizontal depth stack)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final cardWidth = (availableWidth - 52).clamp(280.0, 360.0);
                      return SizedBox(
                        height: 228,
                        child: StackedCardsCarouselWidget(
                          key: ValueKey('stacked_carousel_$_currentCardIndex'),
                          controller: StackedCardsController(_currentCardIndex),
                          items: cards,
                          height: 216,
                          width: cardWidth,
                          stackLevels: 2,
                          onItemChanged: (idx) {
                            setState(() => _currentCardIndex = idx);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Acceso Rápido (Credencial, Nuevo Turno, Nuevo Reclamo)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acceso Rápido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.badge_rounded,
                        label: 'Credencial',
                        iconColor: AppColors.primary,
                        onTap: widget.onNavigateToCredencial ?? widget.onNavigateToSoyDelta,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.calendar_month_rounded,
                        label: 'Nuevo Turno',
                        iconColor: AppColors.secondary,
                        onTap: () => SolicitarTurnoModal.show(context, onNavigateToTramites: widget.onNavigateToTramites),
                      ),
                      _buildQuickActionButton(
                        icon: Icons.campaign_rounded,
                        label: 'Nuevo Reclamo',
                        iconColor: AppColors.tertiary,
                        onTap: () => NewReclamoSheet.show(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Agenda Barrial
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Agenda Barrial',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E3A5F),
                                Color(0xFF006C49),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child: Icon(
                                  Icons.festival_rounded,
                                  size: 110,
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Este Sábado • 16:00 hs',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryEmerald,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Gratis',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Feria Fluvial Sostenible & Talleres de Huerta',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Productores locales, intercambio de semillas y música en vivo en la costanera.',
                                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Plaza Central Altos del Delta', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted)),
                                  ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() => _isEventRegistered = !_isEventRegistered);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isEventRegistered ? AppColors.secondaryEmerald : AppColors.surfaceContainerLow,
                                      foregroundColor: _isEventRegistered ? Colors.white : AppColors.primary,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(
                                      _isEventRegistered ? '¡Anotado! ✓' : 'Anotarme',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                ],
              ),
            ),
          ),

          // Civic Poll
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.how_to_vote_rounded, size: 16, color: AppColors.secondary),
                            SizedBox(width: 4),
                            Text(
                              'TU OPINIÓN SUMA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Cierra en 2 días',
                          style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¿Qué mejora priorizarías para el Corredor Verde Delta?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPollOption(0, 'Más luminarias solares LED', '62%'),
                    const SizedBox(height: 6),
                    _buildPollOption(1, 'Estaciones de calistenia y fitness', '24%'),
                    const SizedBox(height: 6),
                    _buildPollOption(2, 'Cámaras conectadas al COD', '14%'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnoCard(dynamic nextTurno, bool isDark) {
    if (nextTurno != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF06182C), Color(0xFF0F2E52)]
                : const [Color(0xFF022448), Color(0xFF1E3A5F)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Badge and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006C49),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6CF8BB).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF6CF8BB)),
                      SizedBox(width: 4),
                      Text(
                        'TURNO CONFIRMADO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6CF8BB),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF7DD3FC)),
                      const SizedBox(width: 4),
                      Text(
                        nextTurno.date,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Service details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextTurno.service,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${nextTurno.locationName} · ${nextTurno.address}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Turno sincronizado con tu calendario Google / Outlook.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event_available_rounded, size: 14),
                    label: const Text('Agendar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Descargando comprobante oficial de turno en PDF...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 14),
                    label: const Text('Comprobante', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: AppColors.onSecondaryContainer,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Empty state: Inviting card to book a turn
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'GESTIÓN DE TURNOS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSecondaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.secondary),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sin turnos programados',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Gestioná turnos para licencias, trámites, tasas y salud sin filas.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => SolicitarTurnoModal.show(context, onNavigateToTramites: widget.onNavigateToTramites),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Solicitar Nuevo Turno', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReclamoCard(dynamic activeReclamo, bool isDark) {
    final statusColor = activeReclamo.status == ReclamoStatus.resuelto
        ? AppColors.secondaryEmerald
        : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Ticket chip + Status Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.campaign_rounded, size: 11, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'TICKET #${activeReclamo.id.length > 4 ? activeReclamo.id.substring(activeReclamo.id.length - 4) : activeReclamo.id}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSecondaryContainer,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activeReclamo.statusLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          // Category and locality
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeReclamo.category,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '📍 ${activeReclamo.locality}',
                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Est: Mañana 14 hs',
                    style: TextStyle(fontSize: 10, color: AppColors.onSurfaceMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          // Visual Stepper
          _buildStepperVisual(activeReclamo.status),
          // Link to Reclamos
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onNavigateToReclamos();
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver seguimiento en Reportes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredencialCard(dynamic user, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF07242B), Color(0xFF0F3D3E)]
              : const [Color(0xFF0F3D3E), Color(0xFF1E5F74)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3D3E).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 12, color: Color(0xFF2DD4BF)),
                    SizedBox(width: 4),
                    Text(
                      'CREDENCIAL CIUDADANA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco_rounded, size: 14, color: Color(0xFF2DD4BF)),
                  SizedBox(width: 3),
                  Text(
                    'SOY DELTA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? 'Leonardo Benveniste',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Socio N° ${user?.memberNumber ?? 'SD-84920'} • DNI ${user?.dni ?? '29.583.026'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Beneficios exclusivos activos en comercios adheridos',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    (widget.onNavigateToCredencial ?? widget.onNavigateToSoyDelta)?.call();
                  },
                  icon: const Icon(Icons.qr_code_rounded, size: 16),
                  label: const Text(
                    'Ver Credencial & QR',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DD4BF),
                    foregroundColor: const Color(0xFF0F3D3E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperVisual(ReclamoStatus status) {
    int currentStep = 1; // 0: Ingresado, 1: Cuadrilla, 2: Resuelto
    if (status == ReclamoStatus.recibido || status == ReclamoStatus.enRevision) currentStep = 0;
    if (status == ReclamoStatus.enCuadrilla) currentStep = 1;
    if (status == ReclamoStatus.resuelto) currentStep = 2;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 30,
          right: 30,
          top: 14,
          child: Container(
            height: 3,
            color: AppColors.surfaceContainerHigh,
          ),
        ),
        Positioned(
          left: 30,
          width: currentStep == 0 ? 0 : (currentStep == 1 ? 140 : 280),
          top: 14,
          child: Container(
            height: 3,
            color: AppColors.secondaryEmerald,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepItem(0, currentStep >= 0, 'Ingresado', Icons.check_rounded),
            _buildStepItem(1, currentStep >= 1, 'Cuadrilla', Icons.engineering_rounded),
            _buildStepItem(2, currentStep >= 2, 'Resuelto', Icons.done_all_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildStepItem(int stepIndex, bool isActive, String label, IconData icon) {
    final isDone = isActive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? (isDark ? AppColors.darkSecondary : AppColors.secondaryEmerald)
                  : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh),
            ),
            child: Icon(
              icon,
              size: 15,
              color: isDone ? Colors.white : (isDark ? AppColors.darkOnSurfaceMuted : AppColors.outline),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone
                  ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                  : (isDark ? AppColors.darkOnSurfaceMuted : AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollOption(int index, String label, String percentage) {
    final isSelected = _selectedPollOption == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPollOption = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.darkSecondary.withValues(alpha: 0.22)
                  : AppColors.secondaryContainer.withValues(alpha: 0.35))
              : (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLowest),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkSecondary : AppColors.secondary)
                : (isDark ? AppColors.darkCardBorder : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.darkSecondary : AppColors.onSecondaryContainer)
                      : (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                ),
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? (isDark ? AppColors.darkSecondary : AppColors.secondary)
                    : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
