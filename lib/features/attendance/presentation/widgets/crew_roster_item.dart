import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/status_toggle_chips.dart';

/// Roster card item displaying crew member details, inline status toggle, and remarks.
///
/// Migrated to ForUI in Substep 30.3: Material Card/InkWell replaced with FCard,
/// raw brand-color constants replaced with FTheme semantic tokens.
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
    final theme = FTheme.of(context);

    return Semantics(
      label: 'Kru ${record.userId} — Status: ${record.status.name}',
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: FCard(
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
                          backgroundColor: theme.colors.muted,
                          child: Text(
                            (record.userName ?? record.userId)
                                .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                                .takeLast(2)
                                .toUpperCase(),
                            style: theme.typography.body.xs.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.userName ?? 'Kru ID: ${record.userId}',
                              style: theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colors.foreground,
                              ),
                            ),
                            if (record.loggedBy != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Dicatat oleh: ${record.loggedBy}',
                                style: theme.typography.body.xs.copyWith(
                                  color: theme.colors.mutedForeground,
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
                      color: theme.colors.mutedForeground,
                      onPressed: () => _showRemarksDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StatusToggleChips(
                  currentStatus: record.status,
                  onStatusChanged: onStatusChanged,
                ),
                if (record.remarks != null && record.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 14,
                          color: theme.colors.mutedForeground,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.remarks!,
                            style: theme.typography.body.xs.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colors.mutedForeground,
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
