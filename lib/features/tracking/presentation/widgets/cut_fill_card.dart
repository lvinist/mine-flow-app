import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';

/// Card component visualizing a cut/fill measurement record with volume indicators.
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
    final netVolume = record.netVolumeM3;
    final netLabel = netVolume >= 0 ? 'NET CUT' : 'NET FILL';

    return GestureDetector(
      onTap: onTap,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: date and net volume badge
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
                        dateFormat.format(record.measurementDate),
                        style: theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  FBadge(
                    child: Text(
                      '$netLabel: ${netVolume.toStringAsFixed(1)} m³',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Volume bars row
              Row(
                children: [
                  // Cut volume
                  Expanded(
                    child: _VolumeBar(
                      label: 'CUT',
                      value: record.cutVolumeM3,
                      maxValue: record.cutVolumeM3 + record.fillVolumeM3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fill volume
                  Expanded(
                    child: _VolumeBar(
                      label: 'FILL',
                      value: record.fillVolumeM3,
                      maxValue: record.cutVolumeM3 + record.fillVolumeM3,
                    ),
                  ),
                ],
              ),

              // Zone info and notes
              if (record.zoneId.isNotEmpty || record.notes != null) ...[
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
                    if (record.elevationChange != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Elevasi: ${record.elevationChange!.toStringAsFixed(2)} m',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
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
          style: theme.typography.body.xs.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

