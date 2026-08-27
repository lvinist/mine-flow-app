import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
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
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return GestureDetector(
      onTap: onTap,
      child: FCard(
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
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(record.clearingDate),
                        style: theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  FBadge(
                    child: Text(
                      'Plan: ${record.planArea.toStringAsFixed(1)} / Actual: ${record.actualArea.toStringAsFixed(1)} m²',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Area visualization bar
              Row(
                children: [
                  Icon(
                    Icons.straighten,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Varians: ${record.totalAreaHa.toStringAsFixed(2)} Ha',
                    style: theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Progress indicator (completion: actual vs plan)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: record.planArea > 0
                      ? (record.actualArea / record.planArea).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: theme.colors.muted,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colors.primary,
                  ),
                  minHeight: 6,
                ),
              ),

              // Zone and method info
              if (record.zoneId.isNotEmpty || record.method != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (record.zoneId.isNotEmpty) ...[
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          record.zoneId,
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (record.method != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.construction,
                        size: 14,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.method!,
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
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
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.mutedForeground,
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
                      color: theme.colors.destructive,
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
