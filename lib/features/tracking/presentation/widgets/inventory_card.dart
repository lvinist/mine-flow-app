import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';

/// Card component displaying an inventory item with stock level badge
/// and low-stock visual indicator.
class InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAdjustStock;
  final VoidCallback? onDelete;

  const InventoryCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAdjustStock,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isLowStock = item.isLowStock;
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return GestureDetector(
      onTap: onTap,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: name and stock badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(item.category),
                          size: 18,
                          color: theme.colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.itemName,
                            style: theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FBadge(
                    child: Text(
                      '${item.quantityOnHand.toStringAsFixed(item.quantityOnHand == item.quantityOnHand.roundToDouble() ? 0 : 1)} ${item.unit}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category & SKU row
              Row(
                children: [
                  if (item.category != null && item.category!.isNotEmpty) ...[
                    FBadge(child: Text(item.category!)),
                    const SizedBox(width: 8),
                  ],
                  if (item.sku != null && item.sku!.isNotEmpty)
                    Text(
                      'SKU: ${item.sku}',
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Low stock warning
              if (isLowStock)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: theme.colors.destructive.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 14,
                        color: theme.colors.destructive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stok minimum: ${item.minThreshold!.toStringAsFixed(1)} ${item.unit}',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.destructive,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Notes and date
              Row(
                children: [
                  if (item.updatedAt != null) ...[
                    Icon(
                      LucideIcons.refreshCw,
                      size: 12,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(item.updatedAt!),
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onAdjustStock != null)
                    IconButton(
                      icon: const Icon(LucideIcons.shoppingCart, size: 18),
                      onPressed: onAdjustStock,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Sesuaikan Stok',
                    ),
                  if (onAdjustStock != null) const SizedBox(width: 12),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: theme.colors.destructive,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns an appropriate icon for the given inventory category.
  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Fuel / Lubricants':
        return LucideIcons.fuel;
      case 'Explosives / Blasting':
        return LucideIcons.alertTriangle;
      case 'Spare Parts':
        return LucideIcons.wrench;
      case 'Consumables':
        return LucideIcons.boxes;
      case 'Safety Equipment':
        return LucideIcons.shield;
      case 'Tools':
        return LucideIcons.wrench;
      default:
        return LucideIcons.boxes;
    }
  }
}
