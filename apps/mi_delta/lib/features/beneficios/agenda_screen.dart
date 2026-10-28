import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/civic_fixed_header.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onAvatarTap;

  const AgendaScreen({
    super.key,
    this.scrollController,
    this.onAvatarTap,
  });

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  String _selectedCategory = 'TODOS';
  final Set<int> _registeredEvents = {};

  final List<String> _eventCategories = const [
    'TODOS',
    'CULTURA',
    'GASTRONOMÍA',
    'DEPORTES',
    'SALUD ANIMAL',
  ];

  final List<Map<String, dynamic>> _agendaEvents = [
    {
      'id': 1,
      'title': 'Festival Náutico del Delta',
      'date': 'Sábado 18 de Octubre',
      'time': '16:00 a 22:00 hs',
      'location': 'Paseo Costero & Puerto Fluvial',
      'category': 'CULTURA',
      'badge': 'Gratis',
      'icon': Icons.sailing_rounded,
      'description': 'Muestra náutica tradicional, gastronomía isleña, feria artesanal y cierre con música en vivo sobre el río.',
    },
    {
      'id': 2,
      'title': 'Feria de Productores Locales & Agroecológica',
      'date': 'Domingo 19 de Octubre',
      'time': '10:00 a 18:00 hs',
      'location': 'Plaza Central de Altos del Delta',
      'category': 'GASTRONOMÍA',
      'badge': 'Acceso Libre',
      'icon': Icons.eco_rounded,
      'description': 'Frutas y verduras de huertas isleñas, miel de monte, conservas caseras y artesanías en mimbre.',
    },
    {
      'id': 3,
      'title': 'Taller Comunitario de Remo y Kayak',
      'date': 'Martes y Jueves',
      'time': '17:00 a 19:00 hs',
      'location': 'Pista Nacional de Remo y Canotaje',
      'category': 'DEPORTES',
      'badge': 'Inscripción Abierta',
      'icon': Icons.kayaking_rounded,
      'description': 'Clases para principiantes e intermedios dictadas por instructores de la Escuela Municipal de Deportes Náuticos.',
    },
    {
      'id': 4,
      'title': 'Móvil de Zoonosis & Vacunación Antirrábica',
      'date': 'Miércoles 22 de Octubre',
      'time': '09:00 a 13:00 hs',
      'location': 'Estación Dique Luján',
      'category': 'SALUD ANIMAL',
      'badge': 'Sin Turno Previo',
      'icon': Icons.pets_rounded,
      'description': 'Vacunación antirrábica obligatoria gratuita y desparasitación para perros y gatos por orden de llegada.',
    },
    {
      'id': 5,
      'title': 'Cine Bajo las Estrellas',
      'date': 'Viernes 24 de Octubre',
      'time': '20:30 hs',
      'location': 'Anfiteatro del Parque Fluvial',
      'category': 'CULTURA',
      'badge': 'Familiar',
      'icon': Icons.movie_filter_rounded,
      'description': 'Proyección de cine nacional en pantalla gigante. Llevá tu manta o reposera. Puestos de comida y bebidas.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _agendaEvents.where((ev) {
      if (_selectedCategory == 'TODOS') return true;
      return ev['category'] == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: CivicFixedHeader(
        title: 'Agenda Cultural',
        onAvatarTap: widget.onAvatarTap,
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Category Filter
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: _eventCategories.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _eventCategories[index];
                    final isSelected = _selectedCategory == cat;
                    return FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text(cat),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                      ),
                      backgroundColor: AppColors.surfaceContainerLowest,
                      selectedColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                        ),
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                      },
                    );
                  },
                ),
              ),
            ),

            // Header info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Próximos Eventos Barriales',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${filteredEvents.length} actividades',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Events List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = filteredEvents[index];
                    final eventId = event['id'] as int;
                    final isRegistered = _registeredEvents.contains(eventId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  event['icon'] as IconData,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            event['badge'] as String,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          event['category'] as String,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurfaceMuted,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            event['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.onSurfaceMuted),
                              const SizedBox(width: 5),
                              Text(
                                event['date'] as String,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.schedule_rounded, size: 13, color: AppColors.onSurfaceMuted),
                              const SizedBox(width: 4),
                              Text(
                                event['time'] as String,
                                style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 13, color: AppColors.onSurfaceMuted),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  event['location'] as String,
                                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (isRegistered) {
                                        _registeredEvents.remove(eventId);
                                      } else {
                                        _registeredEvents.add(eventId);
                                      }
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isRegistered
                                              ? 'Cancelaste tu asistencia a "${event['title']}"'
                                              : '¡Anotado! Te avisaremos 1 día antes del evento.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    isRegistered ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    isRegistered ? 'Anotado / Recordarme' : 'Asistiré',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRegistered
                                        ? AppColors.secondaryContainer
                                        : AppColors.primary,
                                    foregroundColor: isRegistered
                                        ? AppColors.onSecondaryContainer
                                        : Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enlace de evento copiado al portapapeles.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.share_outlined, size: 18, color: AppColors.primary),
                                tooltip: 'Compartir evento',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surfaceContainerLow,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: filteredEvents.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
