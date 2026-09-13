import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/card_meta_wrap.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Card widget rendering equipment inspection record summary.
///
/// Migrated in STEP-55.7 (FC-54.7-001):
/// Replaced inline [ExpansionTile] with a direct card tap that opens the
/// route-backed inspection detail (/teams/equipment-check/:id).
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
    final isPass = check.status == CheckStatus.passed;
    final statusColor = isPass
        ? theme.colors.secondary
        : theme.colors.destructive;
    final passedCount = check.checklist
        .where((item) => item.isPassed == true)
        .length;
    final totalCount = check.checklist.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                    // Standardized Status Badge (Passed / Flagged)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPass
                              ? LucideIcons.checkCircle
                              : LucideIcons.alertTriangle,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        AppStatusBadge(
                          label: check.status.displayName.toUpperCase(),
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metadata: CheckType badge, inspector id, and time
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
                const SizedBox(height: 12),
                const FDivider(),
                const SizedBox(height: 10),

                // SOP Checklist Summary & Navigation cue (replacing ExpansionTile)
                Row(
                  children: [
                    Icon(
                      isPass
                          ? LucideIcons.checkCircle
                          : LucideIcons.alertTriangle,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SOP Checklist: $passedCount / $totalCount Lolos',
                        style: theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPass
                              ? theme.colors.foreground
                              : theme.colors.destructive,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: theme.colors.mutedForeground,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
