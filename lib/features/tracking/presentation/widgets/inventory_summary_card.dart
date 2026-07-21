import 'package:flutter/material.dart';

/// Summary card displaying aggregate inventory statistics:
/// total items, total low-stock items, and category breakdown counts.
class InventorySummaryCard extends StatelessWidget {
  final int totalItems;
  final int lowStockCount;
  final int categoryCount;

  const InventorySummaryCard({
    super.key,
    required this.totalItems,
    required this.lowStockCount,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.primary.withAlpha(40),
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
                  Icons.inventory_2,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rekapitulasi Inventori',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stat items row
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total Item',
                    value: totalItems.toString(),
                    icon: Icons.inventory_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Kategori',
                    value: categoryCount.toString(),
                    icon: Icons.category_outlined,
                    color: Colors.blue.shade700,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Stok Rendah',
                    value: lowStockCount.toString(),
                    icon: Icons.warning_amber_rounded,
                      color: lowStockCount > 0
                          ? theme.colorScheme.error
                          : const Color(0xFF0891B2),
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
  final Color color;
  final bool isBold;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
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
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
