import 'package:flutter/material.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/status_toggle_chips.dart';

// Phase 2 — shadcn-admin design tokens (DESIGN.md).
const double _kCardRadius = 12;
const double _kInnerRadius = 8;

/// Brand primary — Steel Blue / Navy (#0f172a).
const Color _kBrandPrimary = Color(0xFF0F172A);

/// Roster card item displaying crew member details, inline status toggle, and remarks.
class CrewRosterItem extends StatelessWidget {
  final AttendanceRecord record;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final ValueChanged<String?> onRemarksChanged;

  const CrewRosterItem({
    super.key,
    required this.record,
    required this.onStatusChanged,
    required this.onRemarksChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Kru ${record.userId} — Status: ${record.status.name}',
      container: true,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8.0),
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _kBrandPrimary.withValues(alpha: 0.08),
                        child: Text(
                          record.userId
                              .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                              .takeLast(2)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kru ID: ${record.userId}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (record.loggedBy != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Dicatat oleh: ${record.loggedBy}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_outlined, size: 20),
                    tooltip: 'Tambah Catatan / Remarks',
                    color: colorScheme.onSurfaceVariant,
                    onPressed: () => _showRemarksDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StatusToggleChips(
                currentStatus: record.status,
                onStatusChanged: onStatusChanged,
              ),
              if (record.remarks != null && record.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(_kInnerRadius),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notes,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.remarks!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRemarksDialog(BuildContext context) {
    final controller = TextEditingController(text: record.remarks ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Catatan / Remarks'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Masukkan catatan absensi (misal: Izin setengah hari)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              onRemarksChanged(
                controller.text.trim().isEmpty ? null : controller.text.trim(),
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

extension _StringExtension on String {
  String takeLast(int n) {
    if (length <= n) return this;
    return substring(length - n);
  }
}
