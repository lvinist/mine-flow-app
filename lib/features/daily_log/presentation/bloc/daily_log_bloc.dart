import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';

/// BLoC handling state management for daily logging: the role-aware review
/// list (STEP-55.6), form creation with structured hazard assessment,
/// auto-draft saving, submission, and supervisor approval.
class DailyLogBloc extends Bloc<DailyLogEvent, DailyLogState> {
  final DailyLogRepository _repository;
  final Uuid _uuid;

  DailyLogBloc({required this._repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const DailyLogInitial()) {
    on<LoadDailyLogsListEvent>(_onLoadDailyLogsList);
    on<SelectDailyLogTabEvent>(_onSelectTab);
    on<ApplyDailyLogFiltersEvent>(_onApplyFilters);
    on<InitializeDailyLogFormEvent>(_onInitializeForm);
    on<LogDateChangedEvent>(_onLogDateChanged);
    on<ZoneChangedEvent>(_onZoneChanged);
    on<WeatherChangedEvent>(_onWeatherChanged);
    on<SummaryChangedEvent>(_onSummaryChanged);
    on<NotesChangedEvent>(_onNotesChanged);
    on<HazardChangedEvent>(_onHazardChanged);
    on<AutoSaveDraftEvent>(_onAutoSaveDraft);
    on<SubmitDailyLogEvent>(_onSubmitDailyLog);
    on<ApproveDailyLogEvent>(_onApproveDailyLog);
    on<DeleteDailyLogEvent>(_onDeleteDailyLog);
  }

  /// Status scope for one review tab (spec §4.5 item 1).
  static LogStatus? _statusForTab(DailyLogReviewTab tab) => switch (tab) {
    DailyLogReviewTab.all => null,
    DailyLogReviewTab.draft => LogStatus.draft,
    DailyLogReviewTab.needsApproval => LogStatus.submitted,
    DailyLogReviewTab.approved => LogStatus.approved,
  };

  /// Loads the full log set once, then derives the visible tab list and the
  /// per-tab counts from it — one read, tab switches cost no repository call
  /// beyond the initial load, and counts stay consistent (spec §4.5 item 1).
  Future<void> _loadList(
    Emitter<DailyLogState> emit, {
    DateTime? date,
    String? siteId,
    String? foremanId,
    required DailyLogReviewTab activeTab,
    String? zoneFilter,
    String? foremanFilter,
    String? approvingLogId,
  }) async {
    // The counts need every status, so always fetch unfiltered-by-status,
    // then slice per tab in memory. Data filters (date/zone/foreman) DO
    // apply to the fetch — counts then reflect the filtered scope, which is
    // the honest reading of "counts" on a filtered list.
    final all = await _repository.getDailyLogs(
      date: date,
      siteId: siteId,
      foremanId: foremanId,
    );

    final counts = <DailyLogReviewTab, int>{
      for (final tab in DailyLogReviewTab.values)
        tab: tab == DailyLogReviewTab.all
            ? all.length
            : all.where((l) => l.status == _statusForTab(tab)).length,
    };

    final zone = zoneFilter;
    final foreman = foremanFilter;
    var visible = switch (activeTab) {
      DailyLogReviewTab.all => all,
      _ => all.where((l) => l.status == _statusForTab(activeTab)).toList(),
    };
    if (zone != null) {
      visible = visible.where((l) => l.zoneId == zone).toList();
    }
    if (foreman != null) {
      visible = visible.where((l) => l.foremanId == foreman).toList();
    }

    emit(
      DailyLogsLoaded(
        logs: visible,
        selectedDate: date,
        siteId: siteId,
        statusFilter: _statusForTab(activeTab),
        activeTab: activeTab,
        tabCounts: counts,
        zoneFilter: zone,
        foremanFilter: foreman,
        approvingLogId: approvingLogId,
      ),
    );
  }

  Future<void> _onLoadDailyLogsList(
    LoadDailyLogsListEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    // Preserve workflow context across reloads (returning from a form, a
    // background refresh): the tab and data filters survive unless the
    // event explicitly carries new ones.
    final prev = state is DailyLogsLoaded ? state as DailyLogsLoaded : null;
    final tab = prev?.activeTab ?? DailyLogReviewTab.all;
    emit(const DailyLogLoading());
    try {
      await _loadList(
        emit,
        date: event.date ?? prev?.selectedDate,
        siteId: event.siteId ?? prev?.siteId,
        foremanId: event.foremanId ?? prev?.foremanFilter,
        activeTab: tab,
        zoneFilter: prev?.zoneFilter,
        foremanFilter: prev?.foremanFilter,
      );
    } catch (e) {
      emit(DailyLogError('Gagal memuat log harian: ${e.toString()}'));
    }
  }

  Future<void> _onSelectTab(
    SelectDailyLogTabEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    final current = state;
    if (current is! DailyLogsLoaded) return;
    if (current.activeTab == event.tab) return;
    // Re-derive from the cached scope without a full loading state so the
    // tab/scroll position survives (spec §4.5 items 1–2).
    try {
      await _loadList(
        emit,
        date: current.selectedDate,
        siteId: current.siteId,
        foremanId: current.foremanFilter,
        activeTab: event.tab,
        zoneFilter: current.zoneFilter,
        foremanFilter: current.foremanFilter,
      );
    } catch (e) {
      emit(DailyLogError('Gagal memuat log harian: ${e.toString()}'));
    }
  }

  Future<void> _onApplyFilters(
    ApplyDailyLogFiltersEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    final current = state;
    if (current is! DailyLogsLoaded) return;
    try {
      await _loadList(
        emit,
        date: event.date,
        siteId: current.siteId,
        foremanId: event.foremanId,
        activeTab: current.activeTab,
        zoneFilter: event.zoneId,
        foremanFilter: event.foremanId,
      );
    } catch (e) {
      emit(DailyLogError('Gagal memuat log harian: ${e.toString()}'));
    }
  }

  Future<void> _onInitializeForm(
    InitializeDailyLogFormEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    emit(const DailyLogLoading());
    try {
      // Durable identity first (spec §4.5 item 5 / FC-54.6-007): a record
      // route (`/:id/form`) resolves the log by ID from the repository —
      // `extra` is cache-only and never the identity source.
      DailyLog? log = event.existingLog;
      log ??= event.logId != null
          ? await _repository.getDailyLogById(event.logId!)
          : null;

      log ??= await _repository.getDraftLogForForeman(
        foremanId: event.foremanId,
        date: event.logDate,
        siteId: event.siteId,
      );

      log ??= DailyLog(
        id: _uuid.v4(),
        siteId: event.siteId,
        foremanId: event.foremanId,
        logDate: event.logDate,
        status: LogStatus.draft,
        createdAt: DateTime.now(),
      );

      emit(
        DailyLogFormState(
          log: log,
          autoSaveStatusText: 'Draft tersimpan otomatis',
        ),
      );
    } catch (e) {
      emit(
        DailyLogError(
          'Gagal inisialisasi formulir log harian: ${e.toString()}',
        ),
      );
    }
  }

  void _onLogDateChanged(
    LogDateChangedEvent event,
    Emitter<DailyLogState> emit,
  ) {
    final currentState = state;
    if (currentState is DailyLogFormState) {
      final updatedLog = currentState.log.copyWith(
        logDate: event.date,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(
          log: updatedLog,
          hasUnsavedChanges: true,
          autoSaveStatusText: 'Menyimpan perubahan...',
        ),
      );
    }
  }

  void _onZoneChanged(ZoneChangedEvent event, Emitter<DailyLogState> emit) {
    final currentState = state;
    if (currentState is DailyLogFormState) {
      final updatedLog = currentState.log.copyWith(
        zoneId: event.zoneId,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(
          log: updatedLog,
          hasUnsavedChanges: true,
          autoSaveStatusText: 'Menyimpan perubahan...',
        ),
      );
    }
  }

  void _onWeatherChanged(
    WeatherChangedEvent event,
    Emitter<DailyLogState> emit,
  ) {
    final currentState = state;
    if (currentState is DailyLogFormState) {
      final updatedLog = currentState.log.copyWith(
        weather: event.weather,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(
          log: updatedLog,
          hasUnsavedChanges: true,
          autoSaveStatusText: 'Menyimpan perubahan...',
        ),
      );
    }
  }

  void _onSummaryChanged(
    SummaryChangedEvent event,
    Emitter<DailyLogState> emit,
  ) {
    final currentState = state;
    if (currentState is DailyLogFormState) {
      final updatedLog = currentState.log.copyWith(
        summary: event.summary,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(
          log: updatedLog,
          hasUnsavedChanges: true,
          autoSaveStatusText: 'Menyimpan perubahan...',
        ),
      );
    }
  }

  void _onNotesChanged(NotesChangedEvent event, Emitter<DailyLogState> emit) {
    final currentState = state;
    if (currentState is DailyLogFormState) {
      final updatedLog = currentState.log.copyWith(
        notes: event.notes,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(
          log: updatedLog,
          hasUnsavedChanges: true,
          autoSaveStatusText: 'Menyimpan perubahan...',
        ),
      );
    }
  }

  void _onHazardChanged(HazardChangedEvent event, Emitter<DailyLogState> emit) {
    final currentState = state;
    if (currentState is! DailyLogFormState) return;
    final change = event.change;
    final hazard = currentState.log.hazard;
    // Apply the discrete edit, then normalize: severity/notes/action are
    // meaningful only when a hazard is present (HazardAssessment contract,
    // spec §4.5 item 7). The server coherence CHECK is the twin.
    var next = hazard;
    if (change.state != null) {
      next = HazardAssessment(state: change.state!);
    }
    next = next
        .copyWith(
          severity: change.severity,
          notes: change.notes,
          correctiveAction: change.correctiveAction,
        )
        .normalized();

    final updatedLog = currentState.log.copyWith(
      hazard: next,
      updatedAt: DateTime.now(),
    );
    emit(
      currentState.copyWith(
        log: updatedLog,
        hasUnsavedChanges: true,
        autoSaveStatusText: 'Menyimpan perubahan...',
      ),
    );
  }

  Future<void> _onAutoSaveDraft(
    AutoSaveDraftEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DailyLogFormState) return;
    if (currentState.log.status != LogStatus.draft) return;
    // STEP-48.23 re-run 5 (48.26 gate-5 R-1): bloc events are processed
    // concurrently, and the submit handler holds a pre-submit DRAFT log in
    // state across its awaits — so a debounced (or direct) AutoSaveDraftEvent
    // that starts mid-submit passes the status guard above and races
    // submitDailyLog, writing `draft` over the row it just promoted (web CI:
    // daily_log_journey_test.dart:136). A submit in flight is not an
    // autosave moment; the repository's never-demote contract is the
    // backstop for any path that still reaches it.
    if (currentState.isSubmitting || currentState.isSubmitted) return;

    emit(
      currentState.copyWith(
        isSavingDraft: true,
        autoSaveStatusText: 'Menyimpan draft...',
      ),
    );

    try {
      await _repository.autoSaveDraft(currentState.log);
      emit(
        currentState.copyWith(
          isSavingDraft: false,
          hasUnsavedChanges: false,
          isSaved: true,
          autoSaveStatusText: 'Draft tersimpan otomatis',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSavingDraft: false,
          autoSaveStatusText: 'Gagal menyimpan draft',
        ),
      );
    }
  }

  Future<void> _onSubmitDailyLog(
    SubmitDailyLogEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DailyLogFormState) return;

    if (currentState.log.summary == null ||
        currentState.log.summary!.trim().isEmpty) {
      emit(
        currentState.copyWith(
          errorMessage: 'Ringkasan pekerjaan harian wajib diisi',
        ),
      );
      return;
    }

    // Spec §4.5 item 7 (user-resolved policy, 2026-09-12): the foreman must
    // answer the hazard question before submitting — `not_assessed` is
    // never a valid submitted state; a present hazard also requires a
    // severity. This is the UI twin of the server coherence CHECK.
    final hazard = currentState.log.hazard;
    if (hazard.state == HazardState.notAssessed) {
      emit(
        currentState.copyWith(
          errorMessage: 'Assessment bahaya wajib diisi sebelum mengirim log',
        ),
      );
      return;
    }
    if (hazard.state == HazardState.present && hazard.severity == null) {
      emit(
        currentState.copyWith(errorMessage: 'Pilih tingkat keparahan bahaya'),
      );
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, clearError: true));

    try {
      final updatedLog = currentState.log.copyWith(
        status: LogStatus.submitted,
        updatedAt: DateTime.now(),
      );
      await _repository.autoSaveDraft(updatedLog);
      await _repository.submitDailyLog(updatedLog.id);

      emit(
        currentState.copyWith(
          log: updatedLog,
          isSubmitting: false,
          isSubmitted: true,
          hasUnsavedChanges: false,
          successMessage: 'Log harian berhasil dikirim!',
          autoSaveStatusText: 'Log telah dikirim',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSubmitting: false,
          errorMessage: 'Gagal mengirim log harian: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onApproveDailyLog(
    ApproveDailyLogEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    final current = state;
    if (current is! DailyLogsLoaded) return;

    // Duplicate-tap guard (spec §4.5 item 4): one approval in flight.
    if (current.approvingLogId != null) return;

    // Progress state: the approving card shows its busy state while the
    // list stays mounted (tab/scroll preserved).
    emit(current.copyWith(approvingLogId: event.logId));
    try {
      await _repository.approveDailyLog(
        event.logId,
        approvedBy: event.approvedBy,
      );
      // Refresh counts without losing tab/filters/scroll: reload through
      // the same derived-load path rather than a blank loading screen.
      await _loadList(
        emit,
        date: current.selectedDate,
        siteId: current.siteId,
        foremanId: current.foremanFilter,
        activeTab: current.activeTab,
        zoneFilter: current.zoneFilter,
        foremanFilter: current.foremanFilter,
      );
      emit((state as DailyLogsLoaded).copyWith(clearApprovingLogId: true));
    } catch (e) {
      // Error surfaces on the list (toast) while tab/filters are retained;
      // the failed approval does not change the log's status.
      emit(current.copyWith(clearApprovingLogId: true));
      emit(DailyLogError('Gagal menyetujui log harian: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDailyLog(
    DeleteDailyLogEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    try {
      await _repository.deleteDailyLog(event.logId);

      final currentState = state;
      if (currentState is DailyLogsLoaded) {
        await _loadList(
          emit,
          date: currentState.selectedDate,
          siteId: currentState.siteId,
          foremanId: currentState.foremanFilter,
          activeTab: currentState.activeTab,
          zoneFilter: currentState.zoneFilter,
          foremanFilter: currentState.foremanFilter,
        );
      }
    } catch (e) {
      emit(DailyLogError('Gagal menghapus log harian: ${e.toString()}'));
    }
  }
}
