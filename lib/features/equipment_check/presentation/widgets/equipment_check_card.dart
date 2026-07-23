import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Card widget rendering equipment inspection record details and expandable SOP checklist breakdown.
///
/// Migrated to ForUI in Substep 30.3: Material Card/InkWell replaced with FCard,
/// hardcoded Colors.* constants replaced with FTheme semantic tokens.
class EquipmentCheckCard extends StatelessWidget {
  final EquipmentCheck check;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EquipmentCheckCard({
    super.key,
    required this.check,
    this.onTap,
    this.onDelete,
  });

  IconData _getEquipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.gnss:
        return Icons.gps_fixed;
      case EquipmentType.totalStation:
        return Icons.architecture;
      case EquipmentType.drone:
        return Icons.flight_takeoff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final statusColor = _getStatusColor(check.status, theme);
    final passedCount = check.checklist.where((item) => item.isPassed).length;
    final totalCount = check.checklist.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Equipment Icon, Name, and Status Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEquipmentIcon(check.equipmentType),
                      color: theme.colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          check.equipmentType.displayName,
                          style: theme.typography.body.md.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (check.serialNumber != null &&
                            check.serialNumber!.isNotEmpty)
                          Text(
                            'S/N: ${check.serialNumber}',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status Badge (Passed / Flagged / Failed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          check.status == CheckStatus.passed
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          check.status.displayName.toUpperCase(),
                          style: theme.typography.body.xs.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Metadata Row: CheckType Badge, Inspector ID, and Time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      check.checkType.displayName,
                      style: theme.typography.body.xs.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    check.foremanId,
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(check.checkTime),
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ExpansionTile for detailed SOP item breakdown
              Material(
                type: MaterialType.transparency,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: const Color(0x00000000)),
                  child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
                  title: Text(
                    'SOP Checklist: $passedCount / $totalCount Lolos',
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w600,
                      color: check.isOperational
                          ? theme.colors.secondary
                          : theme.colors.destructive,
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colors.mutedForeground,
                  ),
                  children: [
                    ...check.checklist.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              item.isPassed ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: item.isPassed
                                  ? theme.colors.secondary
                                  : theme.colors.destructive,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.typography.body.xs.copyWith(
                                  color: item.isPassed
                                      ? theme.colors.foreground
                                      : theme.colors.destructive,
                                  fontWeight: item.isPassed
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (item.remarks != null &&
                                item.remarks!.isNotEmpty)
                              Text(
                                item.remarks!,
                                style: theme.typography.body.xs.copyWith(
                                  color: theme.colors.destructive,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (check.remarks != null && check.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colors.muted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Catatan: ${check.remarks}',
                          style: theme.typography.body.xs.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    if (onDelete != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: theme.colors.destructive,
                          ),
                          label: Text(
                            'Hapus Record',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.destructive,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(CheckStatus status, FThemeData theme) {
    switch (status) {
      case CheckStatus.passed:
        return theme.colors.secondary;
      case CheckStatus.flagged:
        return theme.colors.destructive;
      case CheckStatus.failed:
        return theme.colors.destructive;
    }
  }
}
