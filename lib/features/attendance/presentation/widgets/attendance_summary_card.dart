import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Summary card displaying site crew attendance breakdown metrics.
///
/// Migrated to ForUI in Substep 30.3: hardcoded raw status colors replaced with
/// FTheme semantic tokens, Material Card replaced with FCard.
class AttendanceSummaryCard extends StatelessWidget {
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final int sickCount;
  final int leaveCount;
  final AttendanceStatus? activeFilter;
  final ValueChanged<AttendanceStatus?>? onFilterTap;

  const AttendanceSummaryCard({
    super.key,
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    required this.sickCount,
    required this.leaveCount,
    this.activeFilter,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Semantics(
      label: 'Ringkasan kehadiran kru',
      container: true,
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colors.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          size: 20,
                          color: theme.colors.primary,
                          semanticLabel: 'Ikon kelompok',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ringkasan Kehadiran',
                        style: theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colors.foreground,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: $totalCount Kru',
                      style: theme.typography.body.xs.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive: use Wrap on narrow screens (< 480px) to avoid overflow
                  final useWrap = constraints.maxWidth < 480;
                  final tiles = [
                    _buildMetricTile(
                      context,
                      label: 'Hadir',
                      semanticLabel: 'Hadir',
                      count: presentCount,
                      tintColor: theme.colors.primary,
                      isSelected: activeFilter == AttendanceStatus.present,
                      onTap: () => onFilterTap?.call(
                        activeFilter == AttendanceStatus.present
                            ? null
                            : AttendanceStatus.present,
                      ),
                    ),
                    _buildMetricTile(
                      context,
                      label: 'Alpha',
                      semanticLabel: 'Alpha (tidak hadir)',
                      count: absentCount,
                      tintColor: theme.colors.destructive,
                      isSelected: activeFilter == AttendanceStatus.absent,
                      onTap: () => onFilterTap?.call(
                        activeFilter == AttendanceStatus.absent
                            ? null
                            : AttendanceStatus.absent,
                      ),
                    ),
                    _buildMetricTile(
                      context,
                      label: 'Sakit',
                      semanticLabel: 'Sakit',
                      count: sickCount,
                      tintColor: theme.colors.secondary,
                      isSelected: activeFilter == AttendanceStatus.sick,
                      onTap: () => onFilterTap?.call(
                        activeFilter == AttendanceStatus.sick
                            ? null
                            : AttendanceStatus.sick,
                      ),
                    ),
                    _buildMetricTile(
                      context,
                      label: 'Izin',
                      semanticLabel: 'Izin',
                      count: leaveCount,
                      tintColor: theme.colors.primary,
                      isSelected: activeFilter == AttendanceStatus.leave,
                      onTap: () => onFilterTap?.call(
                        activeFilter == AttendanceStatus.leave
                            ? null
                            : AttendanceStatus.leave,
                      ),
                    ),
                  ];

                  if (useWrap) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: tiles[0]),
                            const SizedBox(width: 8),
                            Expanded(child: tiles[1]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: tiles[2]),
                            const SizedBox(width: 8),
                            Expanded(child: tiles[3]),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 8),
                      Expanded(child: tiles[1]),
                      const SizedBox(width: 8),
                      Expanded(child: tiles[2]),
                      const SizedBox(width: 8),
                      Expanded(child: tiles[3]),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String semanticLabel,
    required int count,
    required Color tintColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = FTheme.of(context);

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? tintColor.withValues(alpha: 0.12)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? tintColor : theme.colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: theme.typography.display.md.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tintColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.typography.body.xs.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: tintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
