import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/automation_engine.dart';
import '../services/did_it_controller.dart';
import '../theme/app_theme.dart';

/// Timestamped memory proof ledger answering "When did I last do this?".
class LogbookSheet extends StatefulWidget {
  const LogbookSheet({
    super.key,
    required this.controller,
  });

  final DidItController controller;

  static Future<void> show(
    BuildContext context,
    DidItController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogbookSheet(controller: controller),
    );
  }

  @override
  State<LogbookSheet> createState() => _LogbookSheetState();
}

class _LogbookSheetState extends State<LogbookSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.strings;
        final now = widget.controller.now;
        final entries = widget.controller.history.where((event) {
          if (_filter.trim().isEmpty) return true;
          final q = _filter.toLowerCase();
          return event.itemTitle.toLowerCase().contains(q) ||
              (event.flowTitle?.toLowerCase().contains(q) ?? false);
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            border: Border(top: BorderSide(color: palette.border)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.md,
            AppSpacing.base,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: AppSpacing.xs,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            s.logbookTitle,
                            style: AppTypography.title
                                .copyWith(color: palette.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            s.logbookSubtitle,
                            style: AppTypography.body
                                .copyWith(color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (widget.controller.history.isNotEmpty)
                      TextButton(
                        onPressed: widget.controller.clearHistory,
                        child: Text(
                          s.clearLogbook,
                          style: AppTypography.label
                              .copyWith(color: palette.danger),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  onChanged: (v) => setState(() => _filter = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: s.searchHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Text(
                            s.logbookEmpty,
                            style: AppTypography.body
                                .copyWith(color: palette.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, index) {
                            final ev = entries[index];
                            final ago = AutomationEngine.formatDurationCompact(
                              now.difference(ev.completedAt),
                              isEs: s.isEs,
                            );
                            final stamp = DateFormat('MMM d · HH:mm')
                                .format(ev.completedAt);
                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: palette.surfaceElevated,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: palette.border),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 20,
                                    color: palette.accentPrimary,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          ev.flowTitle != null
                                              ? '${ev.itemTitle} (${ev.flowTitle})'
                                              : ev.itemTitle,
                                          style: AppTypography.body.copyWith(
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '$stamp · ${s.doneAgoLabel(ago)}',
                                          style: AppTypography.label.copyWith(
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.accentTint,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      s.logSourceBadge(ev.source),
                                      style: AppTypography.label.copyWith(
                                        color: palette.accentPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
