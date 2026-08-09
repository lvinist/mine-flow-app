import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

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
    final theme = FTheme.of(context);

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, size: 20, color: theme.colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Rekapitulasi Inventori',
                  style: theme.typography.body.md.copyWith(
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
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Kategori',
                    value: categoryCount.toString(),
                    icon: Icons.category_outlined,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Stok Rendah',
                    value: lowStockCount.toString(),
                    icon: Icons.warning_amber_rounded,
                    isLowStock: lowStockCount > 0,
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
  final bool isLowStock;
  final bool isBold;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isLowStock = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final color = isLowStock
        ? theme.colors.destructive
        : theme.colors.foreground;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLowStock
                ? theme.colors.destructive.withAlpha(20)
                : theme.colors.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.typography.body.md.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
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
