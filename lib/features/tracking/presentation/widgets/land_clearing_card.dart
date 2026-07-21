import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

/// Card component visualizing a land clearing record with area and method info.
class LandClearingCard extends StatelessWidget {
  final LandClearingRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const LandClearingCard({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
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
              // Header row: date and area badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(record.clearingDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0891B2).withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF0891B2).withAlpha(76)),
                    ),
                    child: Text(
                      '${record.areaClearedM2.toStringAsFixed(1)} m²',
                      style: const TextStyle(
                        color: Color(0xFF0891B2),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Area visualization bar
              Row(
                children: [
                  Icon(Icons.straighten, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${record.areaClearedM2.toStringAsFixed(1)} m²  (${record.areaClearedHa.toStringAsFixed(4)} Ha)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Progress indicator (relative)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (record.areaClearedM2 / 10000.0).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF0891B2).withAlpha(25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0891B2)),
                  minHeight: 6,
                ),
              ),

              // Zone and method info
              if (record.zoneId.isNotEmpty ||
                  record.clearingMethod != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (record.zoneId.isNotEmpty) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          record.zoneId,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (record.clearingMethod != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.construction,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.clearingMethod!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Notes
              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  record.notes!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // Delete button
              if (onDelete != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
