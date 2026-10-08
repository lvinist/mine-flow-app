import 'dart:convert';

import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_state.dart';

/// The editable fields only; restored state never supplies roster or record IDs.
class RestoredAttendanceValues {
  const RestoredAttendanceValues({required this.status, required this.remarks});

  final AttendanceStatus? status;
  final String? remarks;
}

/// Versioned, framework-only draft data. Authorization and roster data are reloaded.
class AttendanceDraftRestoration {
  const AttendanceDraftRestoration({
    required this.date,
    required this.isDirty,
    required this.values,
  });

  final DateTime date;
  final bool isDirty;
  final Map<String, RestoredAttendanceValues> values;

  /// Captures editable values without persisting success, errors, or sync state.
  static String encode(AttendanceFormLoaded state) => jsonEncode({
    'version': 1,
    'date': state.date.toIso8601String().substring(0, 10),
    'dirty': state.isDirty,
    'values': {
      for (final draft in state.drafts)
        draft.userId: {'status': draft.status?.name, 'remarks': draft.remarks},
    },
  });

  /// Rejects malformed or incompatible data rather than manufacturing a draft.
  static AttendanceDraftRestoration? decode(String? serialized) {
    if (serialized == null) return null;
    try {
      final data = jsonDecode(serialized);
      if (data is! Map<String, dynamic> ||
          data['version'] != 1 ||
          data['dirty'] is! bool ||
          data['date'] is! String ||
          data['values'] is! Map<String, dynamic>) {
        return null;
      }
      final dateText = data['date'] as String;
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText)) return null;
      final date = DateTime.tryParse(dateText);
      if (date == null || date.toIso8601String().substring(0, 10) != dateText) {
        return null;
      }
      final values = <String, RestoredAttendanceValues>{};
      for (final entry in (data['values'] as Map<String, dynamic>).entries) {
        final row = entry.value;
        if (row is! Map<String, dynamic> ||
            !row.containsKey('status') ||
            !row.containsKey('remarks') ||
            (row['remarks'] != null && row['remarks'] is! String)) {
          return null;
        }
        final statusText = row['status'];
        final status = AttendanceStatus.values
            .where((value) => value.name == statusText)
            .firstOrNull;
        if (statusText != null && status == null) return null;
        values[entry.key] = RestoredAttendanceValues(
          status: status,
          remarks: row['remarks'] as String?,
        );
      }
      return AttendanceDraftRestoration(
        date: date,
        isDirty: data['dirty'] as bool,
        values: values,
      );
    } on FormatException {
      return null;
    }
  }
}
