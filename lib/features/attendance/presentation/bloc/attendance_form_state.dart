import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_crew_draft.dart';

/// Presentation-level per-record sync truth (spec §4.4 item 6, FC-54.5-007).
///
/// This is derived from the shared offline sync queue — it is deliberately
/// separate from [AttendanceSyncState]... attendance status itself, so the
/// card can show "Izin · Menunggu sinkronisasi" without conflating the two.
enum AttendanceSyncState { queued, syncing, failed, synced }

/// Base state for the batch attendance form bloc.
abstract class AttendanceFormState extends Equatable {
  const AttendanceFormState();

  @override
  List<Object?> get props => [];
}

/// Before the first load completes.
class AttendanceFormInitial extends AttendanceFormState {
  const AttendanceFormInitial();
}

/// Loading the roster draft for a date/site.
class AttendanceFormLoading extends AttendanceFormState {
  final DateTime date;
  final String? siteId;

  const AttendanceFormLoading({required this.date, this.siteId});

  @override
  List<Object?> get props => [date, siteId];
}

/// Draft rows loaded; the sheet is interactive.
class AttendanceFormLoaded extends AttendanceFormState {
  /// One draft per roster crew member (unset rows carry null status).
  final List<AttendanceCrewDraft> drafts;

  final DateTime date;
  final String? siteId;

  /// Whether user edits differ from the loaded baseline (D4 dirty guard).
  final bool isDirty;

  /// Whether a save is in flight (footer disabled + busy dismissal).
  final bool isSubmitting;

  /// First row failing submit validation, for focus/scroll (spec §4.4 item 8).
  final String? firstInvalidUserId;

  /// Validation message to show on the sheet with input intact.
  final String? validationError;

  /// Repository-level save failure; input stays intact for recovery.
  final String? saveError;

  /// One-shot success message after a batch save.
  final String? successMessage;

  /// Per-record sync truth keyed by crew user id.
  final Map<String, AttendanceSyncState> syncStates;

  const AttendanceFormLoaded({
    required this.drafts,
    required this.date,
    this.siteId,
    this.isDirty = false,
    this.isSubmitting = false,
    this.firstInvalidUserId,
    this.validationError,
    this.saveError,
    this.successMessage,
    this.syncStates = const {},
  });

  /// Number of crew rows in the batch (footer `Simpan Absensi (N Kru)`).
  int get crewCount => drafts.length;

  /// Crew ids whose row still lacks a status or required reason.
  List<String> get invalidUserIds => [
    for (final draft in drafts)
      if (draft.isInvalidForSubmit) draft.userId,
  ];

  AttendanceFormLoaded copyWith({
    List<AttendanceCrewDraft>? drafts,
    DateTime? date,
    String? siteId,
    bool? isDirty,
    bool? isSubmitting,
    String? firstInvalidUserId,
    bool clearFirstInvalid = false,
    String? validationError,
    bool clearValidationError = false,
    String? saveError,
    bool clearSaveError = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    Map<String, AttendanceSyncState>? syncStates,
  }) {
    return AttendanceFormLoaded(
      drafts: drafts ?? this.drafts,
      date: date ?? this.date,
      siteId: siteId ?? this.siteId,
      isDirty: isDirty ?? this.isDirty,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      firstInvalidUserId: clearFirstInvalid
          ? null
          : (firstInvalidUserId ?? this.firstInvalidUserId),
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      syncStates: syncStates ?? this.syncStates,
    );
  }

  @override
  List<Object?> get props => [
    drafts,
    date,
    siteId,
    isDirty,
    isSubmitting,
    firstInvalidUserId,
    validationError,
    saveError,
    successMessage,
    syncStates,
  ];
}

/// Roster load failure.
class AttendanceFormError extends AttendanceFormState {
  final String message;
  final DateTime date;
  final String? siteId;

  const AttendanceFormError({
    required this.message,
    required this.date,
    this.siteId,
  });

  @override
  List<Object?> get props => [message, date, siteId];
}
