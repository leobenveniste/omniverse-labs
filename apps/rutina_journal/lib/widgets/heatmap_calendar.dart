import 'package:flutter/material.dart';
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
    final sortedDates = data.keys.toList()..sort((a, b) => a.compareTo(b));

    // 7 rows (one for each weekday), each tile is 14x14 with 3px gap:
    // Total height = (7 * 14) + (6 * 3) + 4 = 120px
    const double tileHeight = 14;
    const double tileSpacing = 3;
    const double gridHeight = (7 * tileHeight) + (6 * tileSpacing) + 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consistencia diaria',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Menos ',
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
                      ' Más',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Strictly height-constrained Grid of tiles
            SizedBox(
              height: gridHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Wrap(
                  direction: Axis.vertical,
                  spacing: tileSpacing,
                  runSpacing: tileSpacing,
                  children: List.generate(sortedDates.length, (i) {
                    final date = sortedDates[i];
                    final rate = data[date] ?? 0.0;
                    final color = _getColorForIntensity(context, rate);

                    return Container(
                      width: tileHeight,
                      height: tileHeight,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
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
