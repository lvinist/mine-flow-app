import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/presentation/widgets/card_meta_wrap.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';

/// Card component visualizing a cut/fill measurement record with volume indicators.
///
/// STEP-48.22 (re-run, finding R-2 / BH-015): the header and metadata rows were
/// fixed `Row`s, and the list screen sized every tile with a fixed
/// `childAspectRatio`, so this card overflowed both horizontally (long badge and
/// zone text) and vertically (80 px on the bottom in CI run 33480009094). The
/// rows are now [CardMetaWrap]s of shrinkable [CardMetaChip]s and the card sizes
/// to its content.
class CutFillCard extends StatelessWidget {
  final CutFillRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CutFillCard({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final netVolume = record.netVolume;
    // CF-014: BCM/LCM are measurement bases, not cut vs fill.
    const netLabel = 'SETARA BANK';

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
              // Header: date and net volume badge.
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
                      dateFormat.format(record.measurementDate),
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FBadge(
                    child: Text(
                      '$netLabel: ${netVolume.toStringAsFixed(1)} m³',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Volume bars row
              Row(
                children: [
                  // BCM volume
                  Expanded(
                    child: _VolumeBar(
                      label: 'BCM',
                      value: record.bcmVolume,
                      maxValue: record.bcmVolume + record.lcmVolume,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // LCM volume
                  Expanded(
                    child: _VolumeBar(
                      label: 'LCM',
                      value: record.lcmVolume,
                      maxValue: record.bcmVolume + record.lcmVolume,
                    ),
                  ),
                ],
              ),

              // Zone, material type and elevation info
              if (record.zoneId.isNotEmpty ||
                  record.materialType != null ||
                  record.elevationChange != null ||
                  record.notes != null) ...[
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
                    if (record.materialType != null)
                      CardMetaChip(
                        icon: Icon(
                          LucideIcons.boxes,
                          size: 14,
                          color: theme.colors.mutedForeground,
                        ),
                        label: Text(
                          record.materialType!,
                          overflow: TextOverflow.ellipsis,
                          style: metaStyle,
                        ),
                      ),
                    if (record.elevationChange != null)
                      CardMetaChip(
                        icon: Icon(
                          LucideIcons.trendingUp,
                          size: 14,
                          color: theme.colors.mutedForeground,
                        ),
                        label: Text(
                          'Elevasi: ${record.elevationChange!.toStringAsFixed(2)} m',
                          overflow: TextOverflow.ellipsis,
                          style: metaStyle,
                        ),
                      ),
                  ],
                ),
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metaStyle,
                  ),
                ],
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

/// Internal bar widget showing a volume value with a proportional background bar.
class _VolumeBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;

  const _VolumeBar({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.typography.body.xs.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: theme.colors.muted,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colors.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(1)} m³',
          overflow: TextOverflow.ellipsis,
          style: theme.typography.body.xs.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
