import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_crew_draft.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_state.dart';

/// Owns the batch attendance sheet's editable state (STEP-55.5, spec §4.4).
///
/// The sheet is a **draft layer** above the existing repository: roster rows
/// without a persisted record start unset (null status — never pre-marked
/// present), edits update [AttendanceCrewDraft]s, and submit materializes
/// only the set rows into non-null-status [AttendanceRecord]s through
/// `saveAttendanceBatch`. Per-record sync truth (queued/syncing/failed/
/// synced, spec §4.4 item 6 / FC-54.5-007) is derived from the sync queue
/// box, keyed by the record id inside each queue item's payload.
class AttendanceFormBloc
    extends Bloc<AttendanceFormEvent, AttendanceFormState> {
  final AttendanceRepository _repository;

  /// Source of the real site roster (`users.id` UUIDs).
  final AuthRepository? _authRepository;

  /// Reads the shared sync queue so per-record sync truth stays honest.
  final SyncQueueManager? _syncQueueManager;

  final Uuid _uuid;

  StreamSubscription<List<SyncQueueItem>>? _queueSubscription;

  AttendanceFormBloc({
    required this._repository,
    this._authRepository,
    this._syncQueueManager,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       super(const AttendanceFormInitial()) {
    on<AttendanceFormStarted>(_onStarted);
    on<AttendanceFormStatusSelected>(_onStatusSelected);
    on<AttendanceFormRemarksChanged>(_onRemarksChanged);
    on<AttendanceFormBulkMarkPresent>(_onBulkMarkPresent);
    on<AttendanceFormDateChanged>(_onDateChanged);
    on<AttendanceFormSubmitted>(_onSubmitted);
    on<AttendanceFormRetrySyncRequested>(_onRetrySync);
    on<AttendanceFormQueueChanged>(_onQueueChanged);

    _queueSubscription = _syncQueueManager?.queueRepository.watchAll().listen(
      (items) => add(AttendanceFormQueueChanged(items)),
    );
  }

  String? _resolveSiteId(AttendanceFormState state) =>
      (state is AttendanceFormLoaded) ? state.siteId : null;

  Future<void> _onStarted(
    AttendanceFormStarted event,
    Emitter<AttendanceFormState> emit,
  ) async {
    emit(AttendanceFormLoading(date: event.date, siteId: event.siteId));
    try {
      final drafts = await _loadDrafts(date: event.date, siteId: event.siteId);
      emit(
        AttendanceFormLoaded(
          drafts: drafts,
          date: event.date,
          siteId: event.siteId,
        ),
      );
    } catch (e) {
      emit(
        AttendanceFormError(
          message: 'Gagal memuat daftar kru: ${e.toString()}',
          date: event.date,
          siteId: event.siteId,
        ),
      );
    }
  }

  /// Loads the roster draft: every site crew member, with the persisted
  /// record for this date joined in. Crew without a record start unset —
  /// never pre-marked present (spec §4.4 item 1).
  Future<List<AttendanceCrewDraft>> _loadDrafts({
    required DateTime date,
    required String? siteId,
  }) async {
    final authRepository = _authRepository;
    if (authRepository == null) {
      // No auth wiring (tests): fall back to records-only so the sheet still
      // renders persisted rows instead of an empty roster.
      final records = await _repository.getAttendanceForDate(
        date,
        siteId: siteId,
      );
      return [
        for (final record in records)
          AttendanceCrewDraft(
            userId: record.userId,
            userName: record.userName ?? record.userId,
            role: record.role,
            status: record.status,
            remarks: record.remarks,
            existingRecord: record,
          ),
      ];
    }

    final roster = await authRepository.getSiteRoster(siteId: siteId);
    if (roster.isEmpty) {
      return const [];
    }
    final records = await _repository.getAttendanceForDate(
      date,
      siteId: siteId,
    );
    final byUser = {for (final record in records) record.userId: record};

    return [
      for (final user in roster)
        AttendanceCrewDraft(
          userId: user.id,
          userName: user.name,
          role: _roleLabel(user.role),
          status: byUser[user.id]?.status,
          remarks: byUser[user.id]?.remarks,
          existingRecord: byUser[user.id],
        ),
    ];
  }

  /// Maps a `users.role` value to the roster's display label.
  static String? _roleLabel(String role) {
    switch (role) {
      case 'supervisor':
        return 'Supervisor';
      case 'foreman':
        return 'Foreman';
      case 'crew':
        return 'Crew';
      default:
        return null;
    }
  }

  void _onStatusSelected(
    AttendanceFormStatusSelected event,
    Emitter<AttendanceFormState> emit,
  ) {
    final state = this.state;
    if (state is! AttendanceFormLoaded) return;

    final drafts = _transformDraft(
      state.drafts,
      userId: event.userId,
      transform: (draft) => draft.copyWith(status: event.status),
    );
    if (drafts == null) return;

    emit(
      state.copyWith(
        drafts: drafts,
        isDirty: true,
        clearValidationError: true,
        clearFirstInvalid: true,
      ),
    );
  }

  void _onRemarksChanged(
    AttendanceFormRemarksChanged event,
    Emitter<AttendanceFormState> emit,
  ) {
    final state = this.state;
    if (state is! AttendanceFormLoaded) return;

    final drafts = _transformDraft(
      state.drafts,
      userId: event.userId,
      transform: (draft) =>
          draft.copyWith(remarks: event.remarks, clearRemarks: event.clear),
    );
    if (drafts == null) return;

    emit(
      state.copyWith(
        drafts: drafts,
        isDirty: true,
        clearValidationError: true,
        clearFirstInvalid: true,
      ),
    );
  }

  /// `Tandai Semua Masuk` (spec §4.4 item 2): marks every **still-unset**
  /// crew member present and never overwrites an explicit Izin/Sakit/Alpa
  /// choice (or an already-set Masuk).
  void _onBulkMarkPresent(
    AttendanceFormBulkMarkPresent event,
    Emitter<AttendanceFormState> emit,
  ) {
    final state = this.state;
    if (state is! AttendanceFormLoaded) return;

    var changedAny = false;
    final drafts = <AttendanceCrewDraft>[];
    for (final draft in state.drafts) {
      if (draft.isUnset) {
        changedAny = true;
        drafts.add(draft.copyWith(status: AttendanceStatus.present));
      } else {
        drafts.add(draft);
      }
    }
    if (!changedAny) return;

    emit(state.copyWith(drafts: drafts, isDirty: true));
  }

  void _onDateChanged(
    AttendanceFormDateChanged event,
    Emitter<AttendanceFormState> emit,
  ) {
    add(AttendanceFormStarted(date: event.date, siteId: _resolveSiteId(state)));
  }

  /// Validates then saves the batch (spec §4.4 item 8): every crew member
  /// must have a status and every Izin/Sakit row a non-blank trimmed reason.
  /// Unset rows are refused with [firstInvalidUserId] set so the sheet can
  /// focus/scroll to the first offender; on success the rows are
  /// materialized and saved, and the sheet reports the per-record sync
  /// truth of the just-saved rows.
  Future<void> _onSubmitted(
    AttendanceFormSubmitted event,
    Emitter<AttendanceFormState> emit,
  ) async {
    final state = this.state;
    if (state is! AttendanceFormLoaded || state.isSubmitting) return;

    final firstInvalid = state.drafts
        .where((draft) => draft.isInvalidForSubmit)
        .firstOrNull;
    if (firstInvalid != null) {
      emit(
        state.copyWith(
          validationError: _validationMessageFor(firstInvalid),
          firstInvalidUserId: firstInvalid.userId,
        ),
      );
      return;
    }

    if (state.drafts.isEmpty) return;

    emit(state.copyWith(isSubmitting: true, clearValidationError: true));

    try {
      final siteId = state.siteId ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
      final records = [
        for (final draft in state.drafts)
          draft.toValidatedRecord(
            newRecordId: _uuid.v4(),
            siteId: siteId,
            date: state.date,
            loggedBy: event.loggedBy,
          ),
      ];
      await _repository.saveAttendanceBatch(records);

      final syncStates = _deriveSyncStates(records);
      emit(
        state.copyWith(
          drafts: [
            for (final record in records)
              AttendanceCrewDraft(
                userId: record.userId,
                userName: record.userName ?? record.userId,
                role: record.role,
                status: record.status,
                remarks: record.remarks,
                existingRecord: record,
              ),
          ],
          isSubmitting: false,
          isDirty: false,
          syncStates: syncStates,
          successMessage: 'Absensi berhasil disimpan offline',
          clearValidationError: true,
          clearSaveError: true,
          clearFirstInvalid: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          saveError: 'Gagal menyimpan absensi: ${e.toString()}',
        ),
      );
    }
  }

  String _validationMessageFor(AttendanceCrewDraft draft) {
    if (draft.status == null) {
      return 'Setiap kru harus memiliki status kehadiran sebelum disimpan.';
    }
    return draft.status == AttendanceStatus.sick
        ? 'Alasan sakit wajib diisi.'
        : 'Alasan izin wajib diisi.';
  }

  /// Explicit per-record sync retry (spec §4.4 item 6): re-enqueues the
  /// failed row and asks the queue manager to drain.
  Future<void> _onRetrySync(
    AttendanceFormRetrySyncRequested event,
    Emitter<AttendanceFormState> emit,
  ) async {
    final queueManager = _syncQueueManager;
    if (queueManager == null) return;

    final failedItems = queueManager.queueRepository
        .getAll()
        .where(
          (item) =>
              item.entityType == 'attendance_records' &&
              item.payloadJson['id'] == event.recordId &&
              item.syncStatus == SyncStatus.failed,
        )
        .toList();

    if (failedItems.isEmpty) return;

    for (final item in failedItems) {
      await queueManager.queueRepository.put(
        item.id,
        item.copyWith(
          syncStatus: SyncStatus.pending,
          retryCount: 0,
          errorMessage: null,
        ),
      );
    }
    unawaited(queueManager.processQueue(isManual: true));
  }

  /// Re-derives per-record sync truth whenever the queue box changes.
  void _onQueueChanged(
    AttendanceFormQueueChanged event,
    Emitter<AttendanceFormState> emit,
  ) {
    final state = this.state;
    if (state is! AttendanceFormLoaded) return;

    final knownIds = state.drafts.map((d) => d.userId).toSet();
    // Draft rows that already have a persisted record carry that record's id;
    // map user -> record id so queue items (keyed by record id) can be
    // attributed to the card that shows them.
    final recordIdByUser = <String, String>{};
    for (final draft in state.drafts) {
      final existing = draft.existingRecord;
      if (existing != null) recordIdByUser[draft.userId] = existing.id;
    }

    final syncStates = <String, AttendanceSyncState>{};
    for (final item in event.items) {
      if (item.entityType != 'attendance_records') continue;
      final recordId = item.payloadJson['id'] as String?;
      if (recordId == null) continue;
      final userId = recordIdByUser.entries
          .where((entry) => entry.value == recordId)
          .map((entry) => entry.key)
          .firstOrNull;
      if (userId == null || !knownIds.contains(userId)) continue;
      syncStates[userId] = _stateForQueueItem(item);
    }

    emit(state.copyWith(syncStates: syncStates));
  }

  /// Maps a queue item to the honest presentation state, most advanced wins
  /// when several items exist for one record (e.g. an old failed item and a
  /// new pending one).
  AttendanceSyncState _stateForQueueItem(SyncQueueItem item) {
    switch (item.syncStatus) {
      case SyncStatus.pending:
        return AttendanceSyncState.queued;
      case SyncStatus.syncing:
        return AttendanceSyncState.syncing;
      case SyncStatus.completed:
        return AttendanceSyncState.synced;
      case SyncStatus.failed:
        return AttendanceSyncState.failed;
    }
  }

  Map<String, AttendanceSyncState> _deriveSyncStates(
    List<AttendanceRecord> records,
  ) {
    final queueManager = _syncQueueManager;
    if (queueManager == null) return const {};

    final result = <String, AttendanceSyncState>{};
    for (final record in records) {
      final items = queueManager.queueRepository
          .getAll()
          .where(
            (item) =>
                item.entityType == 'attendance_records' &&
                item.payloadJson['id'] == record.id,
          )
          .toList();
      if (items.isEmpty) continue;
      result[record.userId] = _stateForQueueItem(items.last);
    }
    return result;
  }

  /// Applies [transform] to the draft with [userId]; null when absent.
  List<AttendanceCrewDraft>? _transformDraft(
    List<AttendanceCrewDraft> drafts, {
    required String userId,
    required AttendanceCrewDraft Function(AttendanceCrewDraft) transform,
  }) {
    final index = drafts.indexWhere((draft) => draft.userId == userId);
    if (index == -1) return null;
    final updated = List<AttendanceCrewDraft>.from(drafts);
    updated[index] = transform(updated[index]);
    return updated;
  }

  @override
  Future<void> close() async {
    await _queueSubscription?.cancel();
    return super.close();
  }
}
