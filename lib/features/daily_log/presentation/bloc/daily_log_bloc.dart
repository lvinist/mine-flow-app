import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';

/// BLoC handling state management for daily logging (form creation, auto-draft saving, and list view).
class DailyLogBloc extends Bloc<DailyLogEvent, DailyLogState> {
  final DailyLogRepository _repository;
  final Uuid _uuid;

  DailyLogBloc({required this._repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const DailyLogInitial()) {
    on<LoadDailyLogsListEvent>(_onLoadDailyLogsList);
    on<InitializeDailyLogFormEvent>(_onInitializeForm);
    on<LogDateChangedEvent>(_onLogDateChanged);
    on<ZoneChangedEvent>(_onZoneChanged);
    on<WeatherChangedEvent>(_onWeatherChanged);
    on<SummaryChangedEvent>(_onSummaryChanged);
    on<NotesChangedEvent>(_onNotesChanged);
    on<AutoSaveDraftEvent>(_onAutoSaveDraft);
    on<SubmitDailyLogEvent>(_onSubmitDailyLog);
    on<ApproveDailyLogEvent>(_onApproveDailyLog);
    on<DeleteDailyLogEvent>(_onDeleteDailyLog);
  }

  Future<void> _onLoadDailyLogsList(
    LoadDailyLogsListEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    emit(const DailyLogLoading());
    try {
      final logs = await _repository.getDailyLogs(
        date: event.date,
        siteId: event.siteId,
        foremanId: event.foremanId,
        status: event.statusFilter,
      );

      emit(
        DailyLogsLoaded(
          logs: logs,
          selectedDate: event.date,
          siteId: event.siteId,
          statusFilter: event.statusFilter,
        ),
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
      DailyLog? log = event.existingLog;

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

  Future<void> _onAutoSaveDraft(
    AutoSaveDraftEvent event,
    Emitter<DailyLogState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DailyLogFormState) return;
    if (currentState.log.status != LogStatus.draft) return;

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
    try {
      await _repository.approveDailyLog(
        event.logId,
        approvedBy: event.approvedBy,
      );

      final currentState = state;
      if (currentState is DailyLogsLoaded) {
        add(
          LoadDailyLogsListEvent(
            date: currentState.selectedDate,
            siteId: currentState.siteId,
            statusFilter: currentState.statusFilter,
          ),
        );
      } else if (currentState is DailyLogFormState) {
        final updatedLog = currentState.log.copyWith(
          status: LogStatus.approved,
          approvedBy: event.approvedBy,
          updatedAt: DateTime.now(),
        );
        emit(
          currentState.copyWith(
            log: updatedLog,
            successMessage: 'Log harian telah disetujui',
          ),
        );
      }
    } catch (e) {
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
        add(
          LoadDailyLogsListEvent(
            date: currentState.selectedDate,
            siteId: currentState.siteId,
            statusFilter: currentState.statusFilter,
          ),
        );
      }
    } catch (e) {
      emit(DailyLogError('Gagal menghapus log harian: ${e.toString()}'));
    }
  }
}
