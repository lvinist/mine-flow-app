import 'package:flutter/material.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

// Phase 2 — shadcn-admin design tokens (DESIGN.md).
const double _kCardRadius = 12;
const double _kMetricRadius = 8;

/// Brand primary — Steel Blue / Navy (#0f172a).
const Color _kBrandPrimary = Color(0xFF0F172A);

/// Summary card displaying site crew attendance breakdown metrics.
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Ringkasan kehadiran kru',
      container: true,
      child: Card(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kCardRadius),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(_kCardRadius),
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
                          color: _kBrandPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.groups_outlined,
                          size: 20,
                          color: Color(0xFF0891B2),
                          semanticLabel: 'Ikon kelompok',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ringkasan Kehadiran',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kBrandPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Total: $totalCount Kru',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
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
                      color: const Color(0xFF15803D),
                      bgColor: const Color(0xFFDCFCE7),
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
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEE2E2),
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
                      color: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFEDD5),
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
                      color: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFDBEAFE),
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
                            const SizedBox(width: 6),
                            Expanded(child: tiles[1]),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: tiles[2]),
                            const SizedBox(width: 6),
                            Expanded(child: tiles[3]),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 6),
                      Expanded(child: tiles[1]),
                      const SizedBox(width: 6),
                      Expanded(child: tiles[2]),
                      const SizedBox(width: 6),
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
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kMetricRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : bgColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(_kMetricRadius),
            border: Border.all(
              color: isSelected
                  ? color
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
