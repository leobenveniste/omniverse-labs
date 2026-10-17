import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/routine.dart';
import '../services/app_services.dart';
import '../services/routine_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import 'paywall_sheet.dart';

class RoutineTemplatesSheet extends StatelessWidget {
  final RoutineService routineService;

  const RoutineTemplatesSheet({
    super.key,
    required this.routineService,
  });

  static Future<void> show(BuildContext context, RoutineService service) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineTemplatesSheet(routineService: service),
    );
  }

  List<Routine> _getCuratedBlueprints(BuildContext context) {
    const uuid = Uuid();
    final l10n = AppLocalizations.of(context);
    final isEs = l10n.locale.languageCode == 'es';

    return [
      Routine(
        id: uuid.v4(),
        title: 'blueprintAdhdMorningTitle',
        description: 'blueprintAdhdMorningDesc',
        iconName: 'wb_sunny',
        reminderTime: '07:30',
        reminderEnabled: true,
        steps: [
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Luz natural y vaso de agua' : 'Natural light & glass of water',
            durationSeconds: 120,
            description: isEs ? 'Abre cortinas y toma agua fresca para despertar tu metabolismo.' : 'Open blinds and drink fresh water to signal wakefulness.',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Movimiento suave o estiramiento' : 'Gentle mobility & stretch',
            durationSeconds: 240,
            description: isEs ? 'Rotación de hombros, cuello y 5 respiraciones profundas.' : 'Shoulder rolls, neck circles, and 5 deep breaths.',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Desayuno o café sin pantallas' : 'Mindful breakfast / tea',
            durationSeconds: 600,
            description: isEs ? 'Come sin revisar redes ni correos para proteger tu atención.' : 'Enjoy without scrolling social media or checking emails.',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Definir el único foco de la mañana' : 'Identify one morning highlight',
            durationSeconds: 180,
            description: isEs ? 'Una sola tarea prioritaria antes de abrir mensajes.' : 'Single key task before opening inboxes or chats.',
          ),
        ],
      ),
      Routine(
        id: uuid.v4(),
        title: 'blueprintDigitalDetoxTitle',
        description: 'blueprintDigitalDetoxDesc',
        iconName: 'nightlight_round',
        reminderTime: '22:00',
        reminderEnabled: true,
        steps: [
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Poner teléfono a cargar fuera de la cama' : 'Phone charging away from bed',
            durationSeconds: 60,
            description: isEs ? 'Activa modo no molestar y déjalo lejos de tu alcance.' : 'Turn on Do Not Disturb and place phone across the room.',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Ducha tibia o cuidado personal' : 'Warm shower or skincare',
            durationSeconds: 480,
            description: isEs ? 'Agua tibia para bajar la temperatura corporal central.' : 'Warm water helps induce sleep by lowering core body temp.',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Lectura en papel o audio suave' : 'Physical book or calm audio',
            durationSeconds: 600,
            description: isEs ? '10 minutos de lectura tranquila con luz cálida y tenue.' : '10 minutes of fiction or soft reflection under warm light.',
          ),
        ],
      ),
      Routine(
        id: uuid.v4(),
        title: 'blueprintDeepWorkWarmupTitle',
        description: 'blueprintDeepWorkWarmupDesc',
        iconName: 'center_focus_strong',
        reminderTime: '09:30',
        steps: [
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Despejar escritorio y cerrar pestañas' : 'Clear desk & close extra tabs',
            durationSeconds: 180,
            description: isEs ? 'Deja a la vista solo lo necesario para el objetivo actual.' : 'Keep visible only what is needed for this focus block.',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Definir entregable concreto del bloque' : 'Define tangible block deliverable',
            durationSeconds: 120,
            description: isEs ? '¿Qué habrá terminado exactamente al concluir los 45 min?' : 'What will be strictly finished at the end of the session?',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? '3 respiraciones diafragmáticas lentas' : '3 slow belly breaths',
            durationSeconds: 60,
            description: isEs ? 'Inhala en 4s, exhala en 6s para calmar el pulso.' : 'Inhale 4s, exhale 6s to settle heart rate and anxiety.',
          ),
        ],
      ),
      Routine(
        id: uuid.v4(),
        title: 'blueprintSundayResetTitle',
        description: 'blueprintSundayResetDesc',
        iconName: 'spa',
        reminderTime: '17:00',
        steps: [
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Revisión rápida de agenda de la semana' : 'Scan upcoming week calendar',
            durationSeconds: 300,
            description: isEs ? 'Identifica compromisos importantes y días demandantes.' : 'Identify critical meetings, travel, or demanding days.',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Vaciar bandeja y notas sueltas' : 'Inbox and loose notes zero',
            durationSeconds: 420,
            description: isEs ? 'Pasa notas de papel y capturas pendientes a una lista.' : 'Process loose paper notes and screenshots into your task list.',
          ),
          RoutineStep(
            id: uuid.v4(),
            title: isEs ? 'Plan de comidas o compras básicas' : 'Meal or grocery outline',
            durationSeconds: 360,
            description: isEs ? 'Define 3 comidas fáciles para evitar pedir comida rápida.' : 'Outline 3 simple meals to prevent midweek takeout burnout.',
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final appServices = AppServices.of(context);
    final premiumService = appServices.premiumService;
    final blueprints = _getCuratedBlueprints(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('templatesTitle'),
                      style: AppTypography.title(theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.t('templatesSubtitle'),
                      style: AppTypography.caption(
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.t('actionClose'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Blueprint List
          Expanded(
            child: ListView.separated(
              itemCount: blueprints.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final blueprint = blueprints[index];
                final localizedTitle = l10n.t(blueprint.title);
                final localizedDesc = l10n.t(blueprint.description);

                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Icon(
                                blueprint.icon,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizedTitle,
                                    style: AppTypography.section(theme.colorScheme.onSurface).copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    '${blueprint.steps.length} ${l10n.t('routineSteps', args: {'count': blueprint.steps.length})} • ${blueprint.totalMinutes}m',
                                    style: AppTypography.caption(
                                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      isMedium: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (localizedDesc.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            localizedDesc,
                            style: AppTypography.body(
                              theme.colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),

                        // Steps Preview Chips
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xxs,
                          children: blueprint.steps.map((step) {
                            final min = (step.durationSeconds / 60).ceil();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                              ),
                              child: Text(
                                '${step.title} (${min}m)',
                                style: AppTypography.caption(theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Use Blueprint Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.add_task_rounded, size: 18),
                            label: Text(l10n.t('useTemplate')),
                            onPressed: () async {
                              HapticsHelper.medium();
                              if (!premiumService.isPro && routineService.routines.length >= 3) {
                                PaywallSheet.show(
                                  context,
                                  customReason: l10n.t('proLimitRoutinesMsg'),
                                );
                                return;
                              }

                              // Create fresh routine with unique step IDs
                              const freshUuid = Uuid();
                              final clonedRoutine = Routine(
                                id: freshUuid.v4(),
                                title: localizedTitle,
                                description: localizedDesc,
                                iconName: blueprint.iconName,
                                reminderTime: blueprint.reminderTime,
                                reminderEnabled: blueprint.reminderEnabled,
                                steps: blueprint.steps
                                    .map((s) => RoutineStep(
                                          id: freshUuid.v4(),
                                          title: s.title,
                                          durationSeconds: s.durationSeconds,
                                          description: s.description,
                                        ))
                                    .toList(),
                              );

                              await routineService.addRoutine(clonedRoutine);

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.t('templateAddedSuccess')),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
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
}
