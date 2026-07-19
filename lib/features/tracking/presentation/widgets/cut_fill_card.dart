import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final netVolume = record.netVolumeM3;

    final netColor = netVolume >= 0
        ? Colors.orange.shade700
        : Colors.blue.shade700;
    final netLabel = netVolume >= 0 ? 'NET CUT' : 'NET FILL';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
              // Header row: date and net volume badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(record.measurementDate),
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
                      color: netColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: netColor.withAlpha(76)),
                    ),
                    child: Text(
                      '$netLabel: ${netVolume.toStringAsFixed(1)} m³',
                      style: TextStyle(
                        color: netColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
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
                      color: Colors.orange,
                      maxValue: record.cutVolumeM3 + record.fillVolumeM3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fill volume
                  Expanded(
                    child: _VolumeBar(
                      label: 'FILL',
                      value: record.fillVolumeM3,
                      color: Colors.blue,
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
                    if (record.elevationChange != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Elevasi: ${record.elevationChange!.toStringAsFixed(2)} m',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
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
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
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
  final Color color;
  final double maxValue;

  const _VolumeBar({
    required this.label,
    required this.value,
    required this.color,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: color.withAlpha(25),
            valueColor: AlwaysStoppedAnimation<Color>(color.withAlpha(153)),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(1)} m³',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
