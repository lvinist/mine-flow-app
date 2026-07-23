import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Card component visualizing a daily log entry with status indicator badge.
///
/// Migrated to ForUI in Substep 30.3: Material Card/InkWell replaced with FCard,
/// hardcoded Colors.orange/blue shades replaced with FTheme semantic tokens.
class DailyLogCard extends StatelessWidget {
  final DailyLog log;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DailyLogCard({super.key, required this.log, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (log.status) {
      case LogStatus.draft:
        statusBgColor = theme.colors.destructive.withValues(alpha: 0.1);
        statusTextColor = theme.colors.destructive;
        statusLabel = 'DRAFT';
        break;
      case LogStatus.submitted:
        statusBgColor = theme.colors.primary.withValues(alpha: 0.1);
        statusTextColor = theme.colors.primary;
        statusLabel = 'TERKIRIM';
        break;
      case LogStatus.approved:
        statusBgColor = theme.colors.secondary.withValues(alpha: 0.15);
        statusTextColor = theme.colors.secondary;
        statusLabel = 'DISETUJUI';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Semantics(
        label: 'Log harian ${dateFormat.format(log.logDate)} - $statusLabel',
        button: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          child: FCard(
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
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: theme.colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(log.logDate),
                            style: theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.foreground,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: theme.typography.body.xs.copyWith(
                            color: statusTextColor,
                            fontWeight: FontWeight.w700,
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
                          color: theme.colors.mutedForeground.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.zoneId!,
                          style: theme.typography.body.xs.copyWith(
                            fontSize: 12,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (log.weather != null) ...[
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 14,
                          color: theme.colors.mutedForeground.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          log.weather!,
                          style: theme.typography.body.xs.copyWith(
                            fontSize: 12,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Summary text
                  if (log.summary != null && log.summary!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      log.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.md.copyWith(
                        fontSize: 13,
                        color: theme.colors.foreground.withValues(alpha: 0.8),
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
                        child: GestureDetector(
                          onTap: onDelete,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colors.destructive.withValues(
                                alpha: 0.7,
                              ),
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
    );
  }
}
