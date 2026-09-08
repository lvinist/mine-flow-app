import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/presentation/widgets/card_meta_wrap.dart';
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
        return LucideIcons.locateFixed;
      case EquipmentType.totalStation:
        return LucideIcons.landmark;
      case EquipmentType.drone:
        return LucideIcons.plane;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final statusColor = _getStatusColor(check.status, theme);
    final passedCount = check.checklist
        .where((item) => item.isPassed == true)
        .length;
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
                              ? LucideIcons.checkCircle
                              : LucideIcons.alertTriangle,
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

              // Metadata: CheckType badge, inspector id, and time.
              //
              // R-2 sweep (STEP-48.22 re-run): this Row overflowed by 169 px at
              // phone width — the inspector id is a UUID and the timestamp is
              // fixed-width, so the two cannot share one line. Same defect class
              // as BH-015, reached by the deep-link journey via
              // /teams/equipment-check.
              CardMetaWrap(
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      check.checkType.displayName,
                      style: theme.typography.body.xs.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CardMetaChip(
                    icon: Icon(
                      LucideIcons.user,
                      size: 14,
                      color: theme.colors.mutedForeground,
                    ),
                    label: Text(
                      check.foremanId,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  CardMetaChip(
                    icon: Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: theme.colors.mutedForeground,
                    ),
                    label: Text(
                      dateFormat.format(check.checkTime),
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
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
                      LucideIcons.chevronDown,
                      color: theme.colors.mutedForeground,
                    ),
                    children: [
                      ...check.checklist.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(
                                item.isPassed == true
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.xCircle,
                                size: 16,
                                color: item.isPassed == true
                                    ? theme.colors.secondary
                                    : theme.colors.destructive,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: theme.typography.body.xs.copyWith(
                                    color: item.isPassed == true
                                        ? theme.colors.foreground
                                        : theme.colors.destructive,
                                    fontWeight: item.isPassed == true
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
                      if (check.remarks != null &&
                          check.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colors.muted,
                            borderRadius: BorderRadius.circular(8),
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
                          child: FButton(
                            variant: FButtonVariant.ghost,
                            onPress: onDelete,
                            prefix: Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: theme.colors.destructive,
                            ),
                            child: Text(
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
