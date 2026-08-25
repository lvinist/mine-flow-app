import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';

/// A card displaying a single [TimelineMilestone] with status indicator.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced hardcoded Colors.*
/// and Theme.of(context).colorScheme with FTheme semantic tokens.
class MilestoneCard extends StatelessWidget {
  final TimelineMilestone milestone;
  final VoidCallback? onTap;

  const MilestoneCard({super.key, required this.milestone, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final statusColor = _statusColor(theme, milestone.status);
    final statusLabel = _statusLabel(milestone.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator dot
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.title,
                        style: theme.typography.body.md.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (milestone.description != null &&
                          milestone.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          milestone.description!,
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _infoChip(
                            theme,
                            Icons.calendar_today,
                            dateFormat.format(milestone.startDate),
                          ),
                          if (milestone.targetDate != null) ...[
                            const SizedBox(width: 8),
                            _infoChip(
                              theme,
                              Icons.flag_outlined,
                              dateFormat.format(milestone.targetDate!),
                            ),
                          ],
                        ],
                      ),
                      if (milestone.targetValue != null ||
                          milestone.actualValue != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (milestone.targetValue != null)
                              Text(
                                'Target: ${_fmtNum(milestone.targetValue!)}',
                                style: theme.typography.body.xs.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            if (milestone.actualValue != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                'Aktual: ${_fmtNum(milestone.actualValue!)}',
                                style: theme.typography.body.xs.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.typography.body.xs.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(FThemeData theme, MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.planned:
        return theme.colors.mutedForeground;
      case MilestoneStatus.inProgress:
        return theme.colors.primary;
      case MilestoneStatus.completed:
        return theme.colors.secondary;
      case MilestoneStatus.overdue:
        return theme.colors.destructive;
    }
  }

  String _statusLabel(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.planned:
        return 'Direncanakan';
      case MilestoneStatus.inProgress:
        return 'Berjalan';
      case MilestoneStatus.completed:
        return 'Selesai';
      case MilestoneStatus.overdue:
        return 'Terlambat';
    }
  }

  String _fmtNum(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  Widget _infoChip(FThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colors.mutedForeground),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
