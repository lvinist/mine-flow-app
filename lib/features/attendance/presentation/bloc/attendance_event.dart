import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Base class for all attendance BLoC events.
abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load attendance records for a specific date and site.
class LoadAttendanceEvent extends AttendanceEvent {
  final DateTime date;
  final String? siteId;

  const LoadAttendanceEvent({required this.date, this.siteId});

  @override
  List<Object?> get props => [date, siteId];
}

/// Event to update date selection.
class ChangeDateEvent extends AttendanceEvent {
  final DateTime date;

  const ChangeDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event to update status of a specific crew member in local state.
class UpdateCrewStatusEvent extends AttendanceEvent {
  final String userId;
  final AttendanceStatus status;
  final String? remarks;

  const UpdateCrewStatusEvent({
    required this.userId,
    required this.status,
    this.remarks,
  });

  @override
  List<Object?> get props => [userId, status, remarks];
}

/// Event to update search text query filter.
class UpdateSearchQueryEvent extends AttendanceEvent {
  final String query;

  const UpdateSearchQueryEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event to filter roster by status.
class FilterByStatusEvent extends AttendanceEvent {
  final AttendanceStatus? statusFilter;

  const FilterByStatusEvent(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

/// Event to save/submit attendance batch to repository.
class SaveAttendanceBatchEvent extends AttendanceEvent {
  const SaveAttendanceBatchEvent();
}

/// Event to initialize default crew roster if no records exist for selected date.
///
/// [userIds] is normally left empty: the bloc then loads the real site roster
/// (actual `users.id` UUIDs) through [AttendanceBloc]'s auth repository.
/// Supplying [userIds] explicitly is for tests only — production code must
/// never fabricate identifiers here, because `attendance_records.user_id` is
/// a UUID foreign key and any non-UUID value is rejected with `22P02`
/// (STEP-48.26 R-6 — the old `KRU-00N` debug codes).
class SeedDefaultRosterEvent extends AttendanceEvent {
  final List<String> userIds;
  final String siteId;

  const SeedDefaultRosterEvent({this.userIds = const [], required this.siteId});

  @override
  List<Object?> get props => [userIds, siteId];
}

/// Event to consume/clear the one-shot success message after it is shown.
class ClearAttendanceSuccessEvent extends AttendanceEvent {
  const ClearAttendanceSuccessEvent();
}
