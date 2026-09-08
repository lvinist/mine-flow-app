import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/presentation/widgets/card_meta_wrap.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

/// Card component visualizing a land clearing record with area and method info.
///
/// STEP-48.22 (re-run, finding R-2 / BH-015): the header and metadata rows were
/// fixed `Row`s, and the list screen sized every tile with a fixed
/// `childAspectRatio`, so this card overflowed both horizontally (53/49/45 px on
/// the right) and vertically (58 px on the bottom) in CI run 33480009094. The
/// rows are now [CardMetaWrap]s of shrinkable [CardMetaChip]s and the card sizes
/// to its content.
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

    final metaStyle = theme.typography.body.xs.copyWith(
      color: theme.colors.mutedForeground,
    );

    return GestureDetector(
      onTap: onTap,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: date and area badge.
              CardMetaWrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                children: [
                  CardMetaChip(
                    spacing: 8,
                    icon: Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: theme.colors.mutedForeground,
                    ),
                    label: Text(
                      dateFormat.format(record.clearingDate),
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FBadge(
                    child: Text(
                      'Plan: ${record.planArea.toStringAsFixed(1)} / Actual: ${record.actualArea.toStringAsFixed(1)} m²',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Area visualization bar
              CardMetaWrap(
                children: [
                  CardMetaChip(
                    icon: Icon(
                      LucideIcons.ruler,
                      size: 14,
                      color: theme.colors.mutedForeground,
                    ),
                    label: Text(
                      'Varians: ${record.totalAreaHa.toStringAsFixed(2)} Ha',
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.xs.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
                CardMetaWrap(
                  children: [
                    if (record.zoneId.isNotEmpty)
                      CardMetaChip(
                        icon: Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: theme.colors.mutedForeground,
                        ),
                        label: Text(
                          record.zoneId,
                          overflow: TextOverflow.ellipsis,
                          style: metaStyle,
                        ),
                      ),
                    if (record.method != null)
                      CardMetaChip(
                        icon: Icon(
                          LucideIcons.construction,
                          size: 14,
                          color: theme.colors.mutedForeground,
                        ),
                        label: Text(
                          record.method!,
                          overflow: TextOverflow.ellipsis,
                          style: metaStyle,
                        ),
                      ),
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
                  style: metaStyle,
                ),
              ],

              // Delete button
              if (onDelete != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.trash2,
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
