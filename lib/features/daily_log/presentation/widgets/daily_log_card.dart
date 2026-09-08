import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/presentation/widgets/card_meta_wrap.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Card component visualizing a daily log entry with status indicator badge.
///
/// Migrated to ForUI in Substep 30.3: Material Card/InkWell replaced with FCard,
/// hardcoded Colors.orange/blue shades replaced with FTheme semantic tokens.
///
/// STEP-48.22 (re-run, finding R-2): the header and metadata rows were fixed
/// `Row`s whose children could not shrink, so a long zone name or weather note
/// overflowed horizontally. Both are now [CardMetaWrap]s of shrinkable
/// [CardMetaChip]s, and the enclosing column sizes to its content instead of a
/// fixed grid tile.
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

    final mutedIconColor = theme.colors.mutedForeground.withValues(alpha: 0.7);
    final metaStyle = theme.typography.body.xs.copyWith(
      fontSize: 12,
      color: theme.colors.mutedForeground,
    );

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: date + status badge.
                  CardMetaWrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      CardMetaChip(
                        spacing: 8,
                        icon: Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: theme.colors.primary,
                        ),
                        label: Text(
                          dateFormat.format(log.logDate),
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colors.foreground,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(8),
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

                  // Metadata: zone + weather (both optional).
                  CardMetaWrap(
                    spacing: 16,
                    children: [
                      if (log.zoneId != null)
                        CardMetaChip(
                          icon: Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: mutedIconColor,
                          ),
                          label: Text(
                            log.zoneId!,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle,
                          ),
                        ),
                      if (log.weather != null)
                        CardMetaChip(
                          icon: Icon(
                            LucideIcons.sun,
                            size: 14,
                            color: mutedIconColor,
                          ),
                          label: Text(
                            log.weather!,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle,
                          ),
                        ),
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
                              LucideIcons.trash2,
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
