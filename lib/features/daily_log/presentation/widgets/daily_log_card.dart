import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Card component visualizing a daily log entry with status indicator badge.
class DailyLogCard extends StatelessWidget {
  final DailyLog log;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DailyLogCard({
    super.key,
    required this.log,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (log.status) {
      case LogStatus.draft:
        statusBgColor = Colors.orange.shade100;
        statusTextColor = Colors.orange.shade900;
        statusLabel = 'DRAFT';
        break;
      case LogStatus.submitted:
        statusBgColor = Colors.blue.shade100;
        statusTextColor = Colors.blue.shade900;
        statusLabel = 'TERKIRIM';
        break;
      case LogStatus.approved:
        statusBgColor = Colors.green.shade100;
        statusTextColor = Colors.green.shade900;
        statusLabel = 'DISETUJUI';
        break;
    }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(log.logDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (log.zoneId != null) ...[
                    Icon(Icons.location_on_outlined,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      log.zoneId!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (log.weather != null) ...[
                    Icon(Icons.wb_sunny_outlined,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      log.weather!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (log.summary != null && log.summary!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  log.summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              if (onDelete != null && log.status == LogStatus.draft) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
