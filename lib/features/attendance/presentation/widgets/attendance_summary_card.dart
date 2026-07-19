import 'package:flutter/material.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? kColorSurfaceDark : kColorSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: kBorderRadius,
        side: BorderSide(color: kColorBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 20,
                      color: isDark ? kColorPrimaryDark : kColorPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ringkasan Kehadiran',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? kColorTextPrimaryDark : kColorTextPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? kColorBorderDark : kColorPrimaryContainer,
                    borderRadius: kBorderRadius,
                  ),
                  child: Text(
                    'Total: $totalCount Kru',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? kColorTextPrimaryDark : kColorPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Hadir',
                        count: presentCount,
                        color: const Color(0xFF15803D),
                        bgColor: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
                        isSelected: activeFilter == AttendanceStatus.present,
                        onTap: () => onFilterTap?.call(
                          activeFilter == AttendanceStatus.present ? null : AttendanceStatus.present,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Alpha',
                        count: absentCount,
                        color: const Color(0xFFDC2626),
                        bgColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                        isSelected: activeFilter == AttendanceStatus.absent,
                        onTap: () => onFilterTap?.call(
                          activeFilter == AttendanceStatus.absent ? null : AttendanceStatus.absent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Sakit',
                        count: sickCount,
                        color: const Color(0xFFEA580C),
                        bgColor: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                        isSelected: activeFilter == AttendanceStatus.sick,
                        onTap: () => onFilterTap?.call(
                          activeFilter == AttendanceStatus.sick ? null : AttendanceStatus.sick,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        label: 'Izin',
                        count: leaveCount,
                        color: const Color(0xFF2563EB),
                        bgColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                        isSelected: activeFilter == AttendanceStatus.leave,
                        onTap: () => onFilterTap?.call(
                          activeFilter == AttendanceStatus.leave ? null : AttendanceStatus.leave,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: kBorderRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : bgColor.withValues(alpha: 0.4),
          borderRadius: kBorderRadius,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
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
    );
  }
}
