import 'package:flutter/material.dart';

import '../models/did_it_models.dart';
import '../services/automation_engine.dart';
import '../services/did_it_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_editor_sheet.dart';
import '../widgets/item_editor_sheet.dart';
import '../widgets/logbook_sheet.dart';
import 'flows_tab.dart';
import 'queue_tab.dart';
import 'settings_screen.dart';

/// Main two-tab workspace (`Queue` & `Flows`) with top proof Logbook & Settings actions.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({
    super.key,
    required this.controller,
  });

  final DidItController controller;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _tabIndex = 0;
  bool _searching = false;

  Future<void> _handleDidIt(DidItItem item, {String source = 'app'}) async {
    final s = widget.controller.strings;
    final now = widget.controller.now;

    if (AutomationEngine.isInCooldown(item, now)) {
      final ago = AutomationEngine.formatDurationCompact(
        now.difference(item.lastDoneAt!),
        isEs: s.isEs,
      );
      final remaining = AutomationEngine.formatDurationCompact(
        AutomationEngine.remainingCooldown(item, now),
        isEs: s.isEs,
      );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(s.cooldownTitle),
          content: Text(s.cooldownMessage(item.title, ago, remaining)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(s.confirmAnyway),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _commitDidIt(item, forceCooldown: true, source: source);
      return;
    }

    await _commitDidIt(item, source: source);
  }

  Future<void> _commitDidIt(
    DidItItem item, {
    bool forceCooldown = false,
    String source = 'app',
  }) async {
    final s = widget.controller.strings;
    final res = await widget.controller.markDone(
      item.id,
      forceCooldown: forceCooldown,
      source: source,
    );
    if (!mounted || res == null) return;

    final message = res.triggeredChainTitle != null
        ? '${s.confirmedToast(item.title)} · ${s.chainTriggeredToast(res.triggeredChainTitle!, s.formatMinutesHuman(item.chainDelayMinutes))}'
        : s.confirmedToast(item.title);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: s.undoCta,
            onPressed: () {
              widget.controller.undoCompletion(res.event.id);
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.strings;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: AppSpacing.base,
            title: _searching
                ? TextField(
                    autofocus: true,
                    onChanged: widget.controller.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: s.searchHint,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  )
                : Row(
                    children: <Widget>[
                      Image.asset(
                        'assets/images/app_logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.verified_rounded,
                          color: palette.accentPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        s.appTitle,
                        style: AppTypography.title.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
            actions: <Widget>[
              IconButton(
                tooltip: s.searchTooltip,
                onPressed: () {
                  setState(() {
                    _searching = !_searching;
                    if (!_searching) {
                      widget.controller.setSearchQuery('');
                    }
                  });
                },
                icon: Icon(
                  _searching ? Icons.close_rounded : Icons.search_rounded,
                ),
              ),
              IconButton(
                tooltip: s.logbookTooltip,
                onPressed: () => LogbookSheet.show(context, widget.controller),
                icon: const Icon(Icons.history_rounded),
              ),
              IconButton(
                tooltip: s.settingsTooltip,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          SettingsScreen(controller: widget.controller),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _tabIndex,
              children: <Widget>[
                QueueTab(
                  controller: widget.controller,
                  onDidItRequested: (item) => _handleDidIt(item, source: 'app'),
                  onJumpToTemplates: () => setState(() => _tabIndex = 1),
                ),
                FlowsTab(
                  controller: widget.controller,
                  onStepCompleted: (step) => _handleDidIt(step, source: 'flow'),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (_tabIndex == 0) {
                ItemEditorSheet.show(
                  context,
                  strings: s,
                  existingItems: widget.controller.items,
                  onSave: widget.controller.saveItem,
                );
              } else {
                FlowEditorSheet.show(
                  context,
                  strings: s,
                  onSave: (flow, steps) => widget.controller.saveFlowWithSteps(
                    flow: flow,
                    steps: steps,
                  ),
                );
              }
            },
            backgroundColor: palette.accentPrimary,
            foregroundColor: palette.onAccentPrimary,
            icon: const Icon(Icons.add_rounded),
            label: Text(_tabIndex == 0 ? s.addItemFab : s.addFlowFab),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
            backgroundColor: palette.surface,
            indicatorColor: palette.accentTint,
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: const Icon(Icons.check_circle_outline_rounded),
                selectedIcon: Icon(
                  Icons.check_circle_rounded,
                  color: palette.accentPrimary,
                ),
                label: s.queueTab,
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_tree_outlined),
                selectedIcon: Icon(
                  Icons.account_tree_rounded,
                  color: palette.accentPrimary,
                ),
                label: s.flowsTab,
              ),
            ],
          ),
        );
      },
    );
  }
}
