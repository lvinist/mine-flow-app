import 'package:equatable/equatable.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Base class for the batch attendance form events (STEP-55.5).
abstract class AttendanceFormEvent extends Equatable {
  const AttendanceFormEvent();

  @override
  List<Object?> get props => [];
}

/// Starts (or restarts) the sheet for a date and site.
class AttendanceFormStarted extends AttendanceFormEvent {
  final DateTime date;
  final String? siteId;

  const AttendanceFormStarted({required this.date, this.siteId});

  @override
  List<Object?> get props => [date, siteId];
}

/// One crew member's inline status choice (Izin/Sakit/Alpa/Masuk).
class AttendanceFormStatusSelected extends AttendanceFormEvent {
  final String userId;
  final AttendanceStatus status;

  const AttendanceFormStatusSelected({
    required this.userId,
    required this.status,
  });

  @override
  List<Object?> get props => [userId, status];
}

/// Edits (or explicitly clears) one crew member's reason.
///
/// [clear] exists so "remove the reason" is a first-class intent instead of
/// a null the copy method would treat as keep-old (spec §4.4 item 5).
class AttendanceFormRemarksChanged extends AttendanceFormEvent {
  final String userId;
  final String? remarks;
  final bool clear;

  const AttendanceFormRemarksChanged({
    required this.userId,
    this.remarks,
    this.clear = false,
  });

  @override
  List<Object?> get props => [userId, remarks, clear];
}

/// `Tandai Semua Masuk` — marks only still-unset rows as present.
class AttendanceFormBulkMarkPresent extends AttendanceFormEvent {
  const AttendanceFormBulkMarkPresent();
}

/// Calendar-picked date change; reloads the draft roster for the new date.
class AttendanceFormDateChanged extends AttendanceFormEvent {
  final DateTime date;

  const AttendanceFormDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

/// Batch submit.
class AttendanceFormSubmitted extends AttendanceFormEvent {
  /// The authenticated user id, recorded as `logged_by`.
  final String? loggedBy;

  const AttendanceFormSubmitted({this.loggedBy});
}

/// Explicit per-record sync retry for a failed queue item.
class AttendanceFormRetrySyncRequested extends AttendanceFormEvent {
  final String recordId;

  const AttendanceFormRetrySyncRequested({required this.recordId});

  @override
  List<Object?> get props => [recordId];
}

/// Internal: the sync queue box changed; re-derive per-record sync truth.
class AttendanceFormQueueChanged extends AttendanceFormEvent {
  final List<SyncQueueItem> items;

  const AttendanceFormQueueChanged(this.items);

  @override
  List<Object?> get props => [items];
}
