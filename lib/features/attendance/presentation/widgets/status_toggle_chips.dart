import 'package:flutter/material.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

// Phase 2 — shadcn-admin design tokens (DESIGN.md).
const double _kChipRadius = 8;

/// Field-friendly quick status selector chips with high contrast and large touch targets.
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
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: AttendanceStatus.values.map((status) {
        final isSelected = status == currentStatus;
        return _buildChip(
          context,
          status: status,
          isSelected: isSelected,
          colorScheme: colorScheme,
        );
      }).toList(),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required AttendanceStatus status,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    Color bg;
    Color border;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case AttendanceStatus.present:
        label = 'Hadir';
        icon = Icons.check_circle_outline;
        bg = isSelected ? const Color(0xFFDCFCE7) : Colors.transparent;
        border = isSelected
            ? const Color(0xFF15803D)
            : colorScheme.outlineVariant.withValues(alpha: 0.5);
        textColor = isSelected
            ? const Color(0xFF14532D)
            : colorScheme.onSurfaceVariant;
        break;

      case AttendanceStatus.absent:
        label = 'Alpha';
        icon = Icons.cancel_outlined;
        bg = isSelected ? const Color(0xFFFEE2E2) : Colors.transparent;
        border = isSelected
            ? const Color(0xFFDC2626)
            : colorScheme.outlineVariant.withValues(alpha: 0.5);
        textColor = isSelected
            ? const Color(0xFF7F1D1D)
            : colorScheme.onSurfaceVariant;
        break;

      case AttendanceStatus.sick:
        label = 'Sakit';
        icon = Icons.local_hospital_outlined;
        bg = isSelected ? const Color(0xFFFFEDD5) : Colors.transparent;
        border = isSelected
            ? const Color(0xFFEA580C)
            : colorScheme.outlineVariant.withValues(alpha: 0.5);
        textColor = isSelected
            ? const Color(0xFF7C2D12)
            : colorScheme.onSurfaceVariant;
        break;

      case AttendanceStatus.leave:
        label = 'Izin';
        icon = Icons.event_busy_outlined;
        bg = isSelected ? const Color(0xFFDBEAFE) : Colors.transparent;
        border = isSelected
            ? const Color(0xFF2563EB)
            : colorScheme.outlineVariant.withValues(alpha: 0.5);
        textColor = isSelected
            ? const Color(0xFF1E3A8A)
            : colorScheme.onSurfaceVariant;
        break;
    }

    return Semantics(
      label: 'Status: $label',
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => onStatusChanged(status) : null,
          borderRadius: BorderRadius.circular(_kChipRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(_kChipRadius),
              border: Border.all(color: border, width: isSelected ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
