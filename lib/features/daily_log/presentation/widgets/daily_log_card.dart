import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/presentation/widgets/card_meta_wrap.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Review-oriented Daily Log card (STEP-55.6, spec §4.5 item 3 /
/// FC-54.6-003/004).
///
/// Shows date, foreman identity, zone, weather/hazard summary, updated
/// time, and an icon+text status. Submitted cards visibly expose review
/// eligibility to supervisors; cards remain read-only entry points until an
/// explicit Edit/Approve action — there is no inline status mutation and no
/// drag/drop transition (spec §4.5 item 1).
class DailyLogCard extends StatelessWidget {
  final DailyLog log;

  /// Real display name for [DailyLog.foremanId]; null renders the raw id
  /// (never a UUID is preferable, but an honest id beats a fabricated name).
  final String? foremanName;

  /// Zone display name for [DailyLog.zoneId], when resolvable.
  final String? zoneName;

  final VoidCallback? onTap;

  /// Explicit supervisor approve action (spec §4.5 item 4): the caller
  /// passes it only when the viewer `isSupervisor` and
  /// `status == submitted`. Busy state disables it while an approval for
  /// this very log is in flight.
  final VoidCallback? onApprove;

  /// Explicit delete action (draft only), behind a confirmation dialog.
  final VoidCallback? onDelete;

  /// Whether an approval for this log is currently in flight.
  final bool isApproving;

  const DailyLogCard({
    super.key,
    required this.log,
    this.foremanName,
    this.zoneName,
    this.onTap,
    this.onApprove,
    this.onDelete,
    this.isApproving = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm', 'id_ID');

    final IconData statusIcon;
    final Color statusBgColor;
    final Color statusTextColor;
    final String statusLabel;
    switch (log.status) {
      case LogStatus.draft:
        statusIcon = LucideIcons.pencilLine;
        statusBgColor = theme.colors.destructive.withValues(alpha: 0.1);
        statusTextColor = theme.colors.destructive;
        statusLabel = 'DRAFT';
      case LogStatus.submitted:
        statusIcon = LucideIcons.send;
        statusBgColor = theme.colors.primary.withValues(alpha: 0.1);
        statusTextColor = theme.colors.primary;
        statusLabel = 'PERLU DISETUJUI';
      case LogStatus.approved:
        statusIcon = LucideIcons.checkCircle;
        statusBgColor = theme.colors.secondary.withValues(alpha: 0.15);
        statusTextColor = theme.colors.secondary;
        statusLabel = 'DISETUJUI';
    }

    final mutedIconColor = theme.colors.mutedForeground.withValues(alpha: 0.7);
    final metaStyle = theme.typography.body.xs.copyWith(
      fontSize: 12,
      color: theme.colors.mutedForeground,
    );

    // Hazard summary (spec §4.5 item 3): icon+text, severity when present.
    final hazard = log.hazard;
    final (hazardIcon, hazardText) = switch (hazard.state) {
      HazardState.present => (
        LucideIcons.alertTriangle,
        'Bahaya: ${hazard.severity?.toValue() ?? '?'}',
      ),
      HazardState.none => (LucideIcons.shieldCheck, 'Tidak ada bahaya'),
      HazardState.notAssessed => (LucideIcons.helpCircle, 'Belum dinilai'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Semantics(
        label:
            'Log harian ${dateFormat.format(log.logDate)}'
            '${foremanName != null ? ', $foremanName' : ''} - $statusLabel'
            '${hazard.state == HazardState.present ? ', $hazardText' : ''}',
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
                  // Header: date + icon+text status badge.
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusTextColor),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: theme.typography.body.xs.copyWith(
                                color: statusTextColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Metadata: foreman identity, zone, weather, hazard.
                  CardMetaWrap(
                    spacing: 16,
                    children: [
                      CardMetaChip(
                        icon: Icon(
                          LucideIcons.user,
                          size: 14,
                          color: mutedIconColor,
                        ),
                        label: Text(
                          foremanName ?? log.foremanId,
                          overflow: TextOverflow.ellipsis,
                          style: metaStyle,
                        ),
                      ),
                      if (zoneName != null || log.zoneId != null)
                        CardMetaChip(
                          icon: Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: mutedIconColor,
                          ),
                          label: Text(
                            zoneName ?? log.zoneId!,
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
                      CardMetaChip(
                        icon: Icon(
                          hazardIcon,
                          size: 14,
                          color: hazard.state == HazardState.present
                              ? theme.colors.destructive
                              : mutedIconColor,
                        ),
                        label: Text(hazardText, style: metaStyle),
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

                  const SizedBox(height: 12),

                  // Footer: updated time + explicit actions.
                  CardMetaWrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      CardMetaChip(
                        icon: Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: mutedIconColor,
                        ),
                        label: Text(
                          log.updatedAt != null
                              ? 'Diperbarui ${timeFormat.format(log.updatedAt!)}'
                              : '—',
                          style: metaStyle,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onApprove != null) ...[
                            FButton(
                              key: const Key('approve_daily_log_button'),
                              variant: FButtonVariant.primary,
                              onPress: isApproving ? null : onApprove,
                              prefix: isApproving
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: FCircularProgress(
                                        size: .sm,
                                        style: .delta(
                                          iconStyle: .delta(
                                            color:
                                                theme.colors.primaryForeground,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Icon(LucideIcons.check),
                              child: Text(
                                isApproving ? 'Menyetujui...' : 'Setujui Log',
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (onDelete != null && log.status == LogStatus.draft)
                            Semantics(
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
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
