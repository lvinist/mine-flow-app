import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Summary card displaying cumulative land clearing area in m² and Hectares.
class ClearingSummaryCard extends StatelessWidget {
  final double totalAreaClearedM2;

  const ClearingSummaryCard({super.key, required this.totalAreaClearedM2});

  /// Converted total cleared area in Hectares (1 ha = 10,000 m²).
  double get totalAreaClearedHa => totalAreaClearedM2 / 10000.0;

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

            // m² and Ha values side by side
            Row(
              children: [
                // Area in m²
                Expanded(
                  child: _StatItem(
                    label: 'Total Luas (m²)',
                    value: '${totalAreaClearedM2.toStringAsFixed(1)} m²',
                    icon: Icons.straighten,
                  ),
                ),
                const SizedBox(width: 8),
                // Area in Hectares
                Expanded(
                  child: _StatItem(
                    label: 'Total Luas (Ha)',
                    value: '${totalAreaClearedHa.toStringAsFixed(2)} Ha',
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

