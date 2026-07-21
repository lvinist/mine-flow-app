import 'package:flutter/material.dart';

/// Summary card displaying aggregated cut/fill volume totals with net balance.
class VolumeSummaryCard extends StatelessWidget {
  final double totalCutM3;
  final double totalFillM3;
  final double totalNetM3;

  const VolumeSummaryCard({
    super.key,
    required this.totalCutM3,
    required this.totalFillM3,
    required this.totalNetM3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final netColor = totalNetM3 >= 0
        ? Colors.orange.shade700
        : Colors.blue.shade700;
    final netLabel = totalNetM3 >= 0 ? 'Net Cut' : 'Net Fill';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.primary.withAlpha(76),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_graph,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rekapitulasi Volume',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cut, Fill, Net values
            Row(
              children: [
                // Cut volume
                Expanded(
                  child: _StatItem(
                    label: 'Total Cut',
                    value: '${totalCutM3.toStringAsFixed(1)} m³',
                    color: Colors.orange,
                    icon: Icons.arrow_circle_down_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                // Fill volume
                Expanded(
                  child: _StatItem(
                    label: 'Total Fill',
                    value: '${totalFillM3.toStringAsFixed(1)} m³',
                    color: Colors.blue,
                    icon: Icons.arrow_circle_up_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                // Net volume
                Expanded(
                  child: _StatItem(
                    label: netLabel,
                    value: '${totalNetM3.toStringAsFixed(1)} m³',
                    color: netColor,
                    icon: Icons.balance_outlined,
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
  final Color color;
  final IconData icon;
  final bool isBold;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
