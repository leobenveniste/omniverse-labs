import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';

class HeatmapCalendar extends StatelessWidget {
  final Map<DateTime, double> data; // Date -> completion rate 0.0 to 1.0

  const HeatmapCalendar({
    super.key,
    required this.data,
  });

  Color _getColorForIntensity(BuildContext context, double rate) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (rate <= 0.0) {
      return theme.colorScheme.surfaceContainerHighest;
    } else if (rate < 0.35) {
      return primary.withValues(alpha: 0.3);
    } else if (rate < 0.7) {
      return primary.withValues(alpha: 0.6);
    } else if (rate < 1.0) {
      return primary.withValues(alpha: 0.85);
    } else {
      return primary; // 100% completion
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sortedDates = data.keys.toList()..sort((a, b) => a.compareTo(b));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const int rows = 7;
            const int weeks = 13; // ~91 days
            const double spacing = 3.0;

            final availableWidth = constraints.maxWidth;
            final double computedTileSize = ((availableWidth - ((weeks - 1) * spacing)) / weeks).clamp(10.0, 24.0);
            final double gridHeight = (rows * computedTileSize) + ((rows - 1) * spacing);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.t('consistencyTitle'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${l10n.t('consistencyLess')} ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        _buildLegendTile(theme.colorScheme.surfaceContainerHighest),
                        const SizedBox(width: 3),
                        _buildLegendTile(theme.colorScheme.primary.withValues(alpha: 0.3)),
                        const SizedBox(width: 3),
                        _buildLegendTile(theme.colorScheme.primary.withValues(alpha: 0.6)),
                        const SizedBox(width: 3),
                        _buildLegendTile(theme.colorScheme.primary),
                        Text(
                          ' ${l10n.t('consistencyMore')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Full-width fitted Heatmap Grid
                SizedBox(
                  height: gridHeight,
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      direction: Axis.vertical,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(sortedDates.length, (i) {
                        final date = sortedDates[i];
                        final rate = data[date] ?? 0.0;
                        final color = _getColorForIntensity(context, rate);

                        return Container(
                          width: computedTileSize,
                          height: computedTileSize,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendTile(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
