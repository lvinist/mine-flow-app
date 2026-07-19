import 'package:flutter/material.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/status_toggle_chips.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
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
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark ? kColorBorderDark : kColorPrimaryContainer,
                      child: Text(
                        record.userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').takeLast(2).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? kColorTextPrimaryDark : kColorPrimary,
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
                            fontWeight: FontWeight.bold,
                            color: isDark ? kColorTextPrimaryDark : kColorTextPrimary,
                          ),
                        ),
                        if (record.loggedBy != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Dicatat oleh: ${record.loggedBy}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? kColorMuted : kColorTextSecondary,
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
                  color: isDark ? kColorMuted : kColorTextSecondary,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? kColorBackgroundDark : kColorBackground,
                  borderRadius: kBorderRadius,
                  border: Border.all(color: kColorBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes, size: 14, color: kColorMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.remarks!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? kColorTextPrimaryDark : kColorTextSecondary,
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
              onRemarksChanged(controller.text.trim().isEmpty ? null : controller.text.trim());
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
