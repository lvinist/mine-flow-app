import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Accent — Cyan / Teal, used sparingly for interactive elements.
const Color _kAccent = Color(0xFF0891B2);

/// Card component visualizing a daily log entry with status indicator badge.
class DailyLogCard extends StatelessWidget {
  final DailyLog log;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DailyLogCard({super.key, required this.log, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (log.status) {
      case LogStatus.draft:
        statusBgColor = Colors.orange.shade50;
        statusTextColor = Colors.orange.shade800;
        statusLabel = 'DRAFT';
        break;
      case LogStatus.submitted:
        statusBgColor = Colors.blue.shade50;
        statusTextColor = Colors.blue.shade800;
        statusLabel = 'TERKIRIM';
        break;
      case LogStatus.approved:
        statusBgColor = Colors.green.shade50;
        statusTextColor = Colors.green.shade800;
        statusLabel = 'DISETUJUI';
        break;
    }

    // Dark mode: use lighter backgrounds for status badges.
    final brightness = theme.brightness;
    if (brightness == Brightness.dark) {
      switch (log.status) {
        case LogStatus.draft:
          statusBgColor = Colors.orange.shade900.withValues(alpha: 0.3);
          statusTextColor = Colors.orange.shade200;
          break;
        case LogStatus.submitted:
          statusBgColor = Colors.blue.shade900.withValues(alpha: 0.3);
          statusTextColor = Colors.blue.shade200;
          break;
        case LogStatus.approved:
          statusBgColor = Colors.green.shade900.withValues(alpha: 0.3);
          statusTextColor = Colors.green.shade200;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Semantics(
        label: 'Log harian ${dateFormat.format(log.logDate)} - $statusLabel',
        button: onTap != null,
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            splashColor: _kAccent.withValues(alpha: 0.06),
            highlightColor: _kAccent.withValues(alpha: 0.04),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: date + status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: _kAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(log.logDate),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Metadata row: zone + weather
                    Row(
                      children: [
                        if (log.zoneId != null) ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.zoneId!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (log.weather != null) ...[
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.weather!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Summary text
                    if (log.summary != null && log.summary!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        log.summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ],

                    // Delete button (draft only)
                    if (onDelete != null && log.status == LogStatus.draft) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Semantics(
                          label: 'Hapus log',
                          button: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: onDelete,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: colorScheme.error.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
