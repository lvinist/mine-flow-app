import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Field-friendly quick status selector chips with high contrast and large touch targets.
///
/// Migrated to ForUI in Substep 30.3: hardcoded raw status colors replaced with
/// FTheme semantic tokens (destructive, primary, accent) and ForUI layout primitives.
class StatusToggleChips extends StatelessWidget {
  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final bool enabled;

  const StatusToggleChips({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: AttendanceStatus.values.map((status) {
        final isSelected = status == currentStatus;
        return _buildChip(context, status: status, isSelected: isSelected);
      }).toList(),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required AttendanceStatus status,
    required bool isSelected,
  }) {
    final theme = FTheme.of(context);
    Color borderColor;
    Color tintColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case AttendanceStatus.present:
        label = 'Hadir';
        icon = Icons.check_circle_outline;
        tintColor = theme.colors.primary;
        borderColor = isSelected ? tintColor : theme.colors.border;
        textColor = isSelected ? tintColor : theme.colors.mutedForeground;
        break;

      case AttendanceStatus.absent:
        label = 'Alpha';
        icon = Icons.cancel_outlined;
        tintColor = theme.colors.destructive;
        borderColor = isSelected ? tintColor : theme.colors.border;
        textColor = isSelected ? tintColor : theme.colors.mutedForeground;
        break;

      case AttendanceStatus.sick:
        label = 'Sakit';
        icon = Icons.local_hospital_outlined;
        tintColor = theme.colors.secondary;
        borderColor = isSelected ? tintColor : theme.colors.border;
        textColor = isSelected ? tintColor : theme.colors.mutedForeground;
        break;

      case AttendanceStatus.leave:
        label = 'Izin';
        icon = Icons.event_busy_outlined;
        tintColor = theme.colors.primary;
        borderColor = isSelected ? tintColor : theme.colors.border;
        textColor = isSelected ? tintColor : theme.colors.mutedForeground;
        break;
    }

    return Semantics(
      label: 'Status: $label',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: enabled ? () => onStatusChanged(status) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuart,
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? tintColor.withValues(alpha: 0.12)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.typography.body.sm.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
