import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/did_it_models.dart';
import '../models/starter_templates.dart';
import '../services/did_it_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_editor_sheet.dart';

/// Flows tab for auto-resetting multi-step checklists, chain templates, and one-tap imports.
class FlowsTab extends StatelessWidget {
  const FlowsTab({
    super.key,
    required this.controller,
    required this.onStepCompleted,
  });

  final DidItController controller;
  final ValueChanged<DidItItem> onStepCompleted;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final s = controller.strings;
    final query = controller.searchQuery.trim().toLowerCase();

    final flows = controller.flows
        .where((f) => query.isEmpty || f.title.toLowerCase().contains(query))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        96,
      ),
      children: <Widget>[
        Text(
          s.activeFlowsHeader,
          style: AppTypography.label.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (flows.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              s.emptyQueueSubtitle,
              style: AppTypography.body.copyWith(color: palette.textSecondary),
            ),
          )
        else
          ...flows.map((flow) {
            final steps = controller.items
                .where((i) => i.flowId == flow.id)
                .toList()
              ..sort((a, b) => a.flowOrder.compareTo(b.flowOrder));
            final doneCount = steps.where((st) => st.flowStepChecked).length;
            final hhmm = '${flow.resetHour.toString().padLeft(2, '0')}:'
                '${flow.resetMinute.toString().padLeft(2, '0')}';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: palette.accentTint,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Icon(
                            DidItIcons.resolve(flow.iconKey),
                            color: palette.accentPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                flow.title,
                                style: AppTypography.title
                                    .copyWith(color: palette.textPrimary),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${s.resetRuleLabel(flow.resetRule.name, flow.resetCooldownMinutes, hhmm)} · ${s.runsCompleted(flow.completedRuns)}',
                                style: AppTypography.label
                                    .copyWith(color: palette.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: s.editFlowTitle,
                          onPressed: () {
                            FlowEditorSheet.show(
                              context,
                              strings: s,
                              initialFlow: flow,
                              initialSteps: steps,
                              onSave: (f, st) => controller.saveFlowWithSteps(
                                flow: f,
                                steps: st,
                              ),
                              onDelete: () => controller.deleteFlow(flow.id),
                            );
                          },
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: steps.isEmpty ? 0 : doneCount / steps.length,
                              backgroundColor: palette.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                palette.accentPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          s.stepsProgress(doneCount, steps.length),
                          style: AppTypography.label
                              .copyWith(color: palette.accentPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...steps.map((step) {
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onStepCompleted(step);
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                            horizontal: AppSpacing.xs,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                step.flowStepChecked
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 22,
                                color: step.flowStepChecked
                                    ? palette.accentPrimary
                                    : palette.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: AppTypography.body.copyWith(
                                    color: step.flowStepChecked
                                        ? palette.textSecondary
                                        : palette.textPrimary,
                                    decoration: step.flowStepChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (doneCount > 0) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            controller.resetFlowManually(flow.id);
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(s.resetFlowCta),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppSpacing.base),
        Text(
          s.starterTemplatesHeader,
          style: AppTypography.label.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...StarterTemplates.catalog.map((tpl) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      DidItIcons.resolve(tpl.iconKey),
                      size: 20,
                      color: palette.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          tpl.title(s.isEs),
                          style: AppTypography.body.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          tpl.subtitle(s.isEs),
                          style: AppTypography.label.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () async {
                      final name =
                          await controller.importStarterTemplate(tpl.key);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(s.importedTemplateToast(name)),
                            ),
                          );
                      }
                    },
                    child: Text(s.importTemplate),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
