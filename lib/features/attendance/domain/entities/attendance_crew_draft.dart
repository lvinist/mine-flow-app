import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Form-only roster draft for one crew member on one date (STEP-55.5,
/// master spec §4.4 item 1).
///
/// A crew member with no persisted record for the selected date must start
/// **unset** — [status] is null and the card renders no selection — instead of
/// being pre-marked as present (the D-contract "never pre-mark present" rule).
/// The persisted [AttendanceRecord] entity keeps a non-null status after
/// validation; only this draft layer is nullable.
///
/// This model never reaches storage or the sync queue on its own: it is
/// materialized into a non-null [AttendanceRecord] at submit time by
/// [toValidatedRecord], or dropped when the crew member is left unset.
class AttendanceCrewDraft extends Equatable {
  /// The crew member's real `users.id` (UUID) — never a fabricated code.
  final String userId;

  /// Real display name, primary label on the card (no UUID copy).
  final String userName;

  /// Position/role label shown as secondary information.
  final String? role;

  /// Nullable draft status; null means the row is unset for this date.
  final AttendanceStatus? status;

  /// Draft reason text; persisted through the record `remarks` field.
  final String? remarks;

  /// The persisted record when one already exists for this date, otherwise
  /// null. Preserved so submit reuses the existing row (same id) instead of
  /// creating a duplicate keyed on the same (user_id, date) tuple.
  final AttendanceRecord? existingRecord;

  const AttendanceCrewDraft({
    required this.userId,
    required this.userName,
    this.role,
    this.status,
    this.remarks,
    this.existingRecord,
  });

  /// Whether the crew member still needs a status choice before submit.
  bool get isUnset => status == null;

  /// Whether a reason is required for the selected status (spec §4.4 item 5:
  /// only `Izin` (leave) and `Sakit` (sick) carry a required reason).
  bool get requiresReason =>
      status == AttendanceStatus.leave || status == AttendanceStatus.sick;

  /// The trimmed reason, or null when blank.
  String? get trimmedRemarks => _trimToNull(remarks);

  /// Whether submit validation fails for this draft row.
  ///
  /// A row is invalid when its status is unset, or when a reason is required
  /// but missing/blank after trimming (spec §4.4 item 8: submit does not
  /// proceed until every crew member has a status and every Izin/Sakit row
  /// has a reason).
  bool get isInvalidForSubmit =>
      status == null || (requiresReason && trimmedRemarks == null);

  /// Builds the persisted, non-null-status record from this draft.
  ///
  /// The crew member must already be set ([status] non-null). When the row
  /// reuses an existing record, remarks are replaced **explicitly** — passing
  /// null clears the stored value rather than silently keeping the old one
  /// (the `remarks ?? existing.remarks` keep-old bug FC-54.5 contract).
  ///
  /// [newRecordId] supplies the record id for a crew member with no persisted
  /// row yet. It must be a real UUID (`attendance_records.id` is a UUID
  /// primary key; a non-UUID id is rejected remotely with `22P02` — the
  /// STEP-48.26 R-6 failure class), so the caller (the form bloc) generates
  /// it at materialization time via the uuid package instead of this domain
  /// layer fabricating one.
  AttendanceRecord toValidatedRecord({
    required String newRecordId,
    required String siteId,
    required DateTime date,
    required String? loggedBy,
  }) {
    final status = this.status;
    if (status == null) {
      throw StateError(
        'Cannot build an attendance record for an unset crew member '
        '($userId). Validate the draft first.',
      );
    }
    final existing = existingRecord;
    if (existing != null) {
      return existing.copyWith(
        status: status,
        // The draft layer is authoritative for remarks: a null reason here
        // means "no reason", so an explicit clear must be passed through the
        // sentinel — otherwise `remarks ?? existing.remarks` would silently
        // resurrect the previously stored reason on the next save (the
        // FC-54.5 contract master spec §4.4 item 5 exists to close).
        remarks: trimmedRemarks,
        clearRemarks: trimmedRemarks == null,
        date: date,
        loggedBy: loggedBy,
        updatedAt: DateTime.now(),
      );
    }
    return AttendanceRecord(
      id: newRecordId,
      siteId: siteId,
      userId: userId,
      userName: userName,
      role: role,
      date: date,
      status: status,
      remarks: trimmedRemarks,
      loggedBy: loggedBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Copies this draft with an optional status and **explicit** remarks.
  ///
  /// Remarks semantics differ from `AttendanceRecord.copyWith` on purpose:
  /// [remarks] is always taken as-is (including null = cleared) because the
  /// caller states its intent explicitly at every call site. The status
  /// change flow may pass [clearRemarks] to drop a non-empty reason that no
  /// longer applies (after the confirmation dialog approved it).
  AttendanceCrewDraft copyWith({
    AttendanceStatus? status,
    bool clearStatus = false,
    String? remarks,
    bool clearRemarks = false,
  }) {
    return AttendanceCrewDraft(
      userId: userId,
      userName: userName,
      role: role,
      status: clearStatus ? null : (status ?? this.status),
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
      existingRecord: existingRecord,
    );
  }

  static String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  List<Object?> get props => [
    userId,
    userName,
    role,
    status,
    remarks,
    existingRecord,
  ];
}
