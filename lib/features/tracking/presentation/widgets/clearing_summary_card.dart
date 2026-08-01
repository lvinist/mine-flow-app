import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Summary card displaying cumulative land clearing area in m² and Hectares,
/// split by Plan vs Actual.
class ClearingSummaryCard extends StatelessWidget {
  final double totalPlanArea;
  final double totalActualArea;

  const ClearingSummaryCard({
    super.key,
    required this.totalPlanArea,
    required this.totalActualArea,
  });

  /// Converted total plan area in Hectares.
  double get totalPlanAreaHa => totalPlanArea / 10000.0;

  /// Converted total actual area in Hectares.
  double get totalActualAreaHa => totalActualArea / 10000.0;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.forest, size: 20, color: theme.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Rekapitulasi Land Clearing',
                  style: theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plan vs Actual and Total Ha side by side
            Row(
              children: [
                // Plan area
                Expanded(
                  child: _StatItem(
                    label: 'Rencana (m²)',
                    value: '${totalPlanArea.toStringAsFixed(1)} m²',
                    icon: Icons.assignment,
                  ),
                ),
                const SizedBox(width: 8),
                // Actual area
                Expanded(
                  child: _StatItem(
                    label: 'Aktual (m²)',
                    value: '${totalActualArea.toStringAsFixed(1)} m²',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                // Total Ha
                Expanded(
                  child: _StatItem(
                    label: 'Total (Ha)',
                    value:
                        '${(totalPlanArea + totalActualArea).toStringAsFixed(2)} Ha',
                    icon: Icons.terrain,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single stat item within the summary card.
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isBold;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colors.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colors.foreground),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.typography.body.sm.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
