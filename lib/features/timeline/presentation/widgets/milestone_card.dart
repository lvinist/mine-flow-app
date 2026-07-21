import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';

/// A card displaying a single [TimelineMilestone] with status indicator.
class MilestoneCard extends StatelessWidget {
  final TimelineMilestone milestone;
  final VoidCallback? onTap;

  const MilestoneCard({super.key, required this.milestone, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final statusColor = _statusColor(context, milestone.status);
    final statusLabel = _statusLabel(milestone.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (milestone.description != null &&
                        milestone.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        milestone.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (milestone.actualValue != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Aktual: ${_fmtNum(milestone.actualValue!)}',
                              style: theme.textTheme.labelSmall?.copyWith(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.planned:
        return Colors.grey;
      case MilestoneStatus.inProgress:
        return Colors.blue;
      case MilestoneStatus.completed:
        return Theme.of(context).colorScheme.primary;
      case MilestoneStatus.overdue:
        return Theme.of(context).colorScheme.error;
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

  Widget _infoChip(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
