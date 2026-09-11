import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_crew_draft.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Unit tests for the form-only nullable roster draft (STEP-55.5, master
/// spec §4.4 item 1) and its explicit-clearing semantics (item 5).
void main() {
  const siteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  final date = DateTime(2026, 9, 11);

  AttendanceCrewDraft draft({
    String userId = 'user-1',
    String userName = 'Alex Supervisor',
    String? role = 'Supervisor',
    AttendanceStatus? status,
    String? remarks,
    AttendanceRecord? existingRecord,
  }) {
    return AttendanceCrewDraft(
      userId: userId,
      userName: userName,
      role: role,
      status: status,
      remarks: remarks,
      existingRecord: existingRecord,
    );
  }

  group('AttendanceCrewDraft — nullable roster rows', () {
    test('a crew member with no record starts unset (never pre-marked '
        'present)', () {
      final row = draft();
      expect(row.status, isNull);
      expect(row.isUnset, isTrue);
      expect(row.isInvalidForSubmit, isTrue);
    });

    test('an existing record keeps its persisted status', () {
      final row = draft(status: AttendanceStatus.sick, remarks: 'Demam');
      expect(row.isUnset, isFalse);
      expect(row.status, AttendanceStatus.sick);
      expect(row.isInvalidForSubmit, isFalse);
    });
  });

  group('AttendanceCrewDraft — reason requirements', () {
    test('reason is required only for Izin (leave) and Sakit (sick)', () {
      expect(draft(status: AttendanceStatus.leave).requiresReason, isTrue);
      expect(draft(status: AttendanceStatus.sick).requiresReason, isTrue);
      expect(draft(status: AttendanceStatus.present).requiresReason, isFalse);
      expect(draft(status: AttendanceStatus.absent).requiresReason, isFalse);
    });

    test('a required reason that is blank after trimming is invalid', () {
      final blank = draft(status: AttendanceStatus.leave, remarks: '   ');
      expect(blank.trimmedRemarks, isNull);
      expect(blank.isInvalidForSubmit, isTrue);

      final filled = draft(status: AttendanceStatus.leave, remarks: '  Izin  ');
      expect(filled.trimmedRemarks, 'Izin');
      expect(filled.isInvalidForSubmit, isFalse);
    });
  });

  group('AttendanceCrewDraft — copyWith explicit clearing', () {
    test('copyWith(status:) sets a status without touching remarks', () {
      final row = draft(status: AttendanceStatus.sick, remarks: 'Demam');
      final updated = row.copyWith(status: AttendanceStatus.present);
      expect(updated.status, AttendanceStatus.present);
      expect(updated.remarks, 'Demam');
    });

    test('copyWith(clearRemarks: true) drops the reason even though the '
        'null remarks argument would otherwise mean keep-old', () {
      final row = draft(status: AttendanceStatus.sick, remarks: 'Demam');
      final cleared = row.copyWith(clearRemarks: true);
      expect(cleared.remarks, isNull);
      expect(cleared.trimmedRemarks, isNull);
      // Status survives the clear.
      expect(cleared.status, AttendanceStatus.sick);
    });

    test('copyWith(clearStatus: true) returns the row to unset', () {
      final row = draft(status: AttendanceStatus.present);
      final reset = row.copyWith(clearStatus: true);
      expect(reset.status, isNull);
      expect(reset.isUnset, isTrue);
    });
  });

  group('AttendanceCrewDraft — toValidatedRecord', () {
    test('refuses an unset row', () {
      expect(
        () => draft().toValidatedRecord(
          newRecordId: 'aaaaaaaa-1111-4111-8111-111111111111',
          siteId: siteId,
          date: date,
          loggedBy: 'foreman-1',
        ),
        throwsStateError,
      );
    });

    test('materializes a new non-null-status record with a caller-supplied '
        'UUID', () {
      const newId = 'aaaaaaaa-1111-4111-8111-111111111111';
      final record = draft(status: AttendanceStatus.present).toValidatedRecord(
        newRecordId: newId,
        siteId: siteId,
        date: date,
        loggedBy: 'foreman-1',
      );

      expect(record.id, newId);
      expect(record.userId, 'user-1');
      expect(record.userName, 'Alex Supervisor');
      expect(record.status, AttendanceStatus.present);
      expect(record.siteId, siteId);
      expect(record.date, date);
      expect(record.loggedBy, 'foreman-1');
      expect(record.remarks, isNull);
    });

    test('reuses an existing record id and explicitly clears remarks when the '
        'reason was removed', () {
      final existing = AttendanceRecord(
        id: 'existing-record-id',
        siteId: siteId,
        userId: 'user-1',
        date: date,
        status: AttendanceStatus.sick,
        remarks: 'Demam',
        loggedBy: 'foreman-0',
        userName: 'Alex Supervisor',
      );

      // The user flipped Sakit → Masuk and confirmed the reason removal.
      final row = draft(
        status: AttendanceStatus.present,
        remarks: null,
        existingRecord: existing,
      ).copyWith(clearRemarks: true);

      final record = row.toValidatedRecord(
        newRecordId: 'unused-new-id',
        siteId: siteId,
        date: date,
        loggedBy: 'foreman-1',
      );

      expect(record.id, 'existing-record-id');
      expect(record.status, AttendanceStatus.present);
      // Explicit clear must NOT resurrect the stored 'Demam'.
      expect(record.remarks, isNull);
    });

    test('trims the reason before persisting', () {
      final record =
          draft(
            status: AttendanceStatus.leave,
            remarks: '   Izin setengah hari   ',
          ).toValidatedRecord(
            newRecordId: 'aaaaaaaa-1111-4111-8111-111111111111',
            siteId: siteId,
            date: date,
            loggedBy: 'foreman-1',
          );
      expect(record.remarks, 'Izin setengah hari');
    });
  });
}
