import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final isLowStock = item.isLowStock;
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isLowStock ? theme.colorScheme.error.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
          width: isLowStock ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
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
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StockBadge(
                    quantity: item.quantityOnHand,
                    unit: item.unit,
                    isLowStock: isLowStock,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category & SKU row
              Row(
                children: [
                  if (item.category != null && item.category!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category!,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (item.sku != null && item.sku!.isNotEmpty)
                    Text(
                      'SKU: ${item.sku}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
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
                    color: theme.colorScheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colorScheme.error.withAlpha(76)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stok minimum: ${item.minThreshold!.toStringAsFixed(1)} ${item.unit}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.error,
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
                      Icons.update,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(item.updatedAt!),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
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
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
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
                      icon: const Icon(
                        Icons.add_shopping_cart_outlined,
                        size: 18,
                      ),
                      onPressed: onAdjustStock,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Sesuaikan Stok',
                    ),
                  if (onAdjustStock != null) const SizedBox(width: 12),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
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
        return Icons.local_gas_station;
      case 'Explosives / Blasting':
        return Icons.warning;
      case 'Spare Parts':
        return Icons.handyman_outlined;
      case 'Consumables':
        return Icons.inventory_2_outlined;
      case 'Safety Equipment':
        return Icons.shield_outlined;
      case 'Tools':
        return Icons.build_outlined;
      default:
        return Icons.inventory_outlined;
    }
  }
}

/// Small badge showing the current stock quantity.
class _StockBadge extends StatelessWidget {
  final double quantity;
  final String unit;
  final bool isLowStock;

  const _StockBadge({
    required this.quantity,
    required this.unit,
    required this.isLowStock,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isLowStock ? Theme.of(context).colorScheme.error : const Color(0xFF0891B2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: bgColor.withAlpha(76)),
      ),
      child: Text(
        '${quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 1)} $unit',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: bgColor,
        ),
      ),
    );
  }
}
