import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/guarded_item.dart';
import '../services/vault_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/guarded_item_card.dart';
import '../widgets/trial_entry_sheet.dart';
import 'settings_screen.dart';

enum _VaultTab { active, history }

/// Single primary Command Center screen for CancelGuard.
class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({
    super.key,
    required this.controller,
  });

  final VaultController controller;

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  _VaultTab _tab = _VaultTab.active;

  VaultController get _ctrl => widget.controller;

  Future<void> _openSettings() async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(controller: _ctrl),
      ),
    );
  }

  Future<void> _openEntrySheet([GuardedItem? existing]) async {
    final result = await showModalBottomSheet<TrialEntryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrialEntrySheet(
        strings: _ctrl.strings,
        currency: _ctrl.currency,
        existingItem: existing,
      ),
    );
    if (result == null || !mounted) return;

    switch (result.action) {
      case TrialSheetAction.save:
        if (existing == null) {
          final created = await _ctrl.addItem(
            name: result.name!,
            amount: result.amount!,
            kind: result.kind!,
            billingCycle: result.billingCycle!,
            chargeAt: result.chargeAt!,
            alertPreset: result.alertPreset!,
            cancelUrl: result.cancelUrl!,
            notes: result.notes!,
          );
          _showSnack(_ctrl.strings.shieldActiveSnackbar(created.name));
        } else {
          await _ctrl.updateItem(
            existing.copyWith(
              name: result.name,
              amount: result.amount,
              kind: result.kind,
              billingCycle: result.billingCycle,
              chargeAt: result.chargeAt,
              alertPreset: result.alertPreset,
              cancelUrl: result.cancelUrl,
              notes: result.notes,
            ),
          );
        }
        break;
      case TrialSheetAction.markCancelled:
        if (existing != null) await _handleMarkCancelled(existing);
        break;
      case TrialSheetAction.delete:
        if (existing != null) await _ctrl.deleteItem(existing.id);
        break;
    }
  }

  Future<void> _handleMarkCancelled(GuardedItem item) async {
    await _ctrl.markCancelled(item.id);
    if (!mounted) return;
    final formatted = _ctrl.strings.formatMoney(_ctrl.currency, item.amount);
    _showSnack(_ctrl.strings.bankedSnackbar(item.name, formatted));
  }

  Future<void> _handleOpenCancelLink(GuardedItem item) async {
    final uri = Uri.tryParse(item.cancelUrl);
    if (uri == null) {
      _showSnack(_ctrl.strings.couldNotOpenLinkSnackbar());
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnack(_ctrl.strings.couldNotOpenLinkSnackbar());
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        final strings = _ctrl.strings;
        final palette = AppPalette.of(context);
        final active = _ctrl.activeItems;
        final urgent = _ctrl.urgentActiveItems;
        final safe = _ctrl.safeActiveItems;
        final history = _ctrl.historyItems;

        final isShowingEmpty =
            (_tab == _VaultTab.active && active.isEmpty) ||
                (_tab == _VaultTab.history && history.isEmpty);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: AppSpacing.base,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.shield_outlined,
                    size: 24,
                    color: palette.accentPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  strings.appTitle,
                  style: AppTypography.title.copyWith(color: palette.textPrimary),
                ),
              ],
            ),
            actions: [
              Tooltip(
                message: strings.settingsTooltip,
                child: IconButton(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_outlined),
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.sm,
                    AppSpacing.base,
                    AppSpacing.base,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroRoiBanner(
                          strings: strings,
                          currency: _ctrl.currency,
                          atRiskAmount: _ctrl.atRiskNext30Days,
                          totalSaved: _ctrl.totalSaved,
                          roiMultiplier: _ctrl.roiMultiplier,
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _SegmentedVaultToggle(
                          activeCount: active.length,
                          historyCount: history.length,
                          selected: _tab,
                          strings: strings,
                          onChanged: (next) {
                            HapticFeedback.selectionClick();
                            setState(() => _tab = next);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (isShowingEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        96.0,
                      ),
                      child: Center(
                        child: _EmptyVaultState(
                          icon: _tab == _VaultTab.active
                              ? Icons.verified_user_outlined
                              : Icons.savings_outlined,
                          title: _tab == _VaultTab.active
                              ? strings.emptyActiveTitle
                              : strings.emptyHistoryTitle,
                          body: _tab == _VaultTab.active
                              ? strings.emptyActiveBody
                              : strings.emptyHistoryBody,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base,
                      0,
                      AppSpacing.base,
                      96.0,
                    ),
                    sliver: SliverList.list(
                      children: [
                        if (_tab == _VaultTab.active) ...[
                          if (urgent.isNotEmpty) ...[
                            _SectionHeader(
                              title: strings.urgentSection,
                              color: palette.dangerText,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final item in urgent) ...[
                              GuardedItemCard(
                                item: item,
                                currency: _ctrl.currency,
                                strings: strings,
                                isHighlighted:
                                    _ctrl.highlightedItemId == item.id,
                                onTap: () => _openEntrySheet(item),
                                onOpenCancelLink: () =>
                                    _handleOpenCancelLink(item),
                                onMarkCancelled: () =>
                                    _handleMarkCancelled(item),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                          if (safe.isNotEmpty) ...[
                            _SectionHeader(
                              title: strings.protectedSection,
                              color: palette.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final item in safe) ...[
                              GuardedItemCard(
                                item: item,
                                currency: _ctrl.currency,
                                strings: strings,
                                isHighlighted:
                                    _ctrl.highlightedItemId == item.id,
                                onTap: () => _openEntrySheet(item),
                                onOpenCancelLink: () =>
                                    _handleOpenCancelLink(item),
                                onMarkCancelled: () =>
                                    _handleMarkCancelled(item),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        ] else ...[
                          _SectionHeader(
                            title: strings.historySection,
                            color: palette.accentPrimary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (final item in history) ...[
                            GuardedItemCard(
                              item: item,
                              currency: _ctrl.currency,
                              strings: strings,
                              onTap: () => _openEntrySheet(item),
                              onOpenCancelLink: () =>
                                  _handleOpenCancelLink(item),
                              onMarkCancelled: () =>
                                  _handleMarkCancelled(item),
                              onRestore: () => _ctrl.restoreItem(item.id),
                              onDelete: () => _ctrl.deleteItem(item.id),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.lightImpact();
              _openEntrySheet();
            },
            backgroundColor: palette.accentPrimary,
            foregroundColor: palette.onAccentPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              strings.guardTrialCta,
              style: AppTypography.title.copyWith(
                color: palette.onAccentPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroRoiBanner extends StatelessWidget {
  const _HeroRoiBanner({
    required this.strings,
    required this.currency,
    required this.atRiskAmount,
    required this.totalSaved,
    required this.roiMultiplier,
  });

  final AppStrings strings;
  final String currency;
  final double atRiskAmount;
  final double totalSaved;
  final double roiMultiplier;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final paidForItself = totalSaved >= VaultController.appPurchasePrice;

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: strings.atRisk30d,
            value: strings.formatMoney(currency, atRiskAmount),
            borderColor: atRiskAmount > 0 ? palette.warning : palette.border,
            valueColor:
                atRiskAmount > 0 ? palette.warningText : palette.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _MetricTile(
            label: strings.totalSaved,
            value: strings.formatMoney(currency, totalSaved),
            borderColor:
                paidForItself ? palette.accentPrimary : palette.border,
            valueColor:
                paidForItself ? palette.accentPrimary : palette.textPrimary,
            badgeText: paidForItself ? strings.roiBadge(roiMultiplier) : null,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.borderColor,
    required this.valueColor,
    this.badgeText,
  });

  final String label;
  final String value;
  final Color borderColor;
  final Color valueColor;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.display.copyWith(color: valueColor),
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: palette.accentTint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                badgeText!,
                style:
                    AppTypography.label.copyWith(color: palette.accentPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentedVaultToggle extends StatelessWidget {
  const _SegmentedVaultToggle({
    required this.activeCount,
    required this.historyCount,
    required this.selected,
    required this.strings,
    required this.onChanged,
  });

  final int activeCount;
  final int historyCount;
  final _VaultTab selected;
  final AppStrings strings;
  final ValueChanged<_VaultTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: '${strings.activeTab} ($activeCount)',
              selected: selected == _VaultTab.active,
              onTap: () => onChanged(_VaultTab.active),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: '${strings.savedHistoryTab} ($historyCount)',
              selected: selected == _VaultTab.history,
              onTap: () => onChanged(_VaultTab.history),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: AppSpacing.minTouchTarget - AppSpacing.sm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? palette.textPrimary : palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.label.copyWith(color: color),
    );
  }
}

class _EmptyVaultState extends StatelessWidget {
  const _EmptyVaultState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44, color: palette.accentPrimary),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: AppTypography.title.copyWith(color: palette.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body,
          style: AppTypography.body.copyWith(color: palette.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
