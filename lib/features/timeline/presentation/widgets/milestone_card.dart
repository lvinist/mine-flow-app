import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';

/// A card displaying a single [TimelineMilestone] with status indicator.
///
/// Phase 2 polish: shadcn-admin card styling, micro-interactions on expand/status,
/// standardised colour tokens and typography.
class MilestoneCard extends StatefulWidget {
  final TimelineMilestone milestone;
  final VoidCallback? onTap;

  const MilestoneCard({super.key, required this.milestone, this.onTap});

  @override
  State<MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<MilestoneCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final m = widget.milestone;
    final statusColor = _statusColor(m.status);
    final statusLabel = _statusLabel(m.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isHovering
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isHovering
              ? theme.colorScheme.outline.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: _isHovering ? 1.0 : 0.5,
        ),
        boxShadow: _isHovering
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _isHovering = v),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator — animated dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (m.description != null && m.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        m.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
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
                          dateFormat.format(m.startDate),
                        ),
                        if (m.targetDate != null) ...[
                          const SizedBox(width: 10),
                          _infoChip(
                            theme,
                            Icons.flag_outlined,
                            dateFormat.format(m.targetDate!),
                          ),
                        ],
                      ],
                    ),
                    if (m.targetValue != null || m.actualValue != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (m.targetValue != null)
                            _valueChip(
                              theme,
                              'Target',
                              _fmtNum(m.targetValue!),
                              theme.colorScheme.onSurfaceVariant,
                            ),
                          if (m.actualValue != null) ...[
                            const SizedBox(width: 10),
                            _valueChip(
                              theme,
                              'Aktual',
                              _fmtNum(m.actualValue!),
                              statusColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge — animated
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.planned:
        return Colors.grey;
      case MilestoneStatus.inProgress:
        return Colors.blue;
      case MilestoneStatus.completed:
        return const Color(0xFF15803D);
      case MilestoneStatus.overdue:
        return const Color(0xFFDC2626);
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

  Widget _valueChip(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
