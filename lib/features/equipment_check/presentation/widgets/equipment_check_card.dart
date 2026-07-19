import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Card widget rendering equipment inspection record details and expandable SOP checklist breakdown.
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

  Color _getStatusColor(CheckStatus status) {
    switch (status) {
      case CheckStatus.passed:
        return const Color(0xFF2E7D32); // Dark Green
      case CheckStatus.flagged:
        return const Color(0xFFED6C02); // Warning Orange
      case CheckStatus.failed:
        return const Color(0xFFD32F2F); // Error Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final statusColor = _getStatusColor(check.status);
    final passedCount = check.checklist.where((item) => item.isPassed).length;
    final totalCount = check.checklist.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEquipmentIcon(check.equipmentType),
                      color: theme.colorScheme.primary,
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (check.serialNumber != null && check.serialNumber!.isNotEmpty)
                          Text(
                            'S/N: ${check.serialNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status Badge (Passed / Flagged / Failed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Metadata Row: CheckType Badge, Inspector ID, and Time
              Row(
                children: [
                  // CheckType Chip (Pre-Work / Post-Work)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      check.checkType.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    check.foremanId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(check.checkTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ExpansionTile for detailed SOP item breakdown
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
                  title: Text(
                    'SOP Checklist: $passedCount / $totalCount Lolos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: check.isOperational
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFED6C02),
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
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
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFD32F2F),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: item.isPassed
                                      ? theme.colorScheme.onSurface
                                      : const Color(0xFFD32F2F),
                                  fontWeight:
                                      item.isPassed ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (item.remarks != null && item.remarks!.isNotEmpty)
                              Text(
                                item.remarks!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
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
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Catatan: ${check.remarks}',
                          style: theme.textTheme.bodySmall?.copyWith(
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
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          label: const Text('Hapus Record', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
