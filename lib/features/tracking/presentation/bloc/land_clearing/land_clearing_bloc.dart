import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';

/// BLoC handling state management for Land Clearing Area tracking:
/// - List view with aggregated totals and filters
/// - Form creation and editing of clearing records
/// - Save and delete operations via repository
///
/// v2: Uses planArea/actualArea instead of areaClearedM2, method instead of clearingMethod.
class LandClearingBloc extends Bloc<LandClearingEvent, LandClearingState> {
  final TrackingRepository _repository;
  final Uuid _uuid;

  LandClearingBloc({required this._repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const LandClearingInitial()) {
    on<LoadLandClearingRecordsEvent>(_onLoadRecords);
    on<InitializeLandClearingFormEvent>(_onInitializeForm);
    on<ZoneChangedEvent>(_onZoneChanged);
    on<PlanAreaChangedEvent>(_onPlanAreaChanged);
    on<ActualAreaChangedEvent>(_onActualAreaChanged);
    on<MethodChangedEvent>(_onMethodChanged);
    on<ClearingDateChangedEvent>(_onClearingDateChanged);
    on<LandClearingNotesChangedEvent>(_onNotesChanged);
    on<SaveLandClearingRecordEvent>(_onSaveRecord);
    on<DeleteLandClearingRecordEvent>(_onDeleteRecord);
  }

  Future<void> _onLoadRecords(
    LoadLandClearingRecordsEvent event,
    Emitter<LandClearingState> emit,
  ) async {
    emit(const LandClearingLoading());
    try {
      final records = await _repository.getLandClearingRecords(
        siteId: event.siteId,
        zoneId: event.zoneId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final totalPlan = records.fold<double>(0.0, (sum, r) => sum + r.planArea);
      final totalActual = records.fold<double>(
        0.0,
        (sum, r) => sum + r.actualArea,
      );

      emit(
        LandClearingRecordsLoaded(
          records: records,
          siteId: event.siteId,
          zoneId: event.zoneId,
          totalPlanArea: totalPlan,
          totalActualArea: totalActual,
        ),
      );
    } catch (e) {
      emit(
        LandClearingError('Gagal memuat data land clearing: ${e.toString()}'),
      );
    }
  }

  Future<void> _onInitializeForm(
    InitializeLandClearingFormEvent event,
    Emitter<LandClearingState> emit,
  ) async {
    emit(const LandClearingLoading());
    try {
      final record =
          event.existingRecord ??
          LandClearingRecord(
            id: _uuid.v4(),
            siteId: event.siteId,
            zoneId: event.zoneId,
            dailyLogId: event.dailyLogId,
            planArea: 0.0,
            actualArea: 0.0,
            clearingDate: DateTime.now(),
            clearedBy: event.foremanId,
            createdAt: DateTime.now(),
          );

      emit(LandClearingFormState(record: record));
    } catch (e) {
      emit(
        LandClearingError(
          'Gagal inisialisasi form land clearing: ${e.toString()}',
        ),
      );
    }
  }

  void _onZoneChanged(
    ZoneChangedEvent event,
    Emitter<LandClearingState> emit,
  ) {
    final currentState = state;
    if (currentState is LandClearingFormState) {
      final updatedRecord = currentState.record.copyWith(
        zoneId: event.zoneId,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onPlanAreaChanged(
    PlanAreaChangedEvent event,
    Emitter<LandClearingState> emit,
  ) {
    final currentState = state;
    if (currentState is LandClearingFormState) {
      final updatedRecord = currentState.record.copyWith(
        planArea: event.planArea,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onActualAreaChanged(
    ActualAreaChangedEvent event,
    Emitter<LandClearingState> emit,
  ) {
    final currentState = state;
    if (currentState is LandClearingFormState) {
      final updatedRecord = currentState.record.copyWith(
        actualArea: event.actualArea,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onMethodChanged(
    MethodChangedEvent event,
    Emitter<LandClearingState> emit,
  ) {
    final currentState = state;
    if (currentState is LandClearingFormState) {
      final updatedRecord = currentState.record.copyWith(
        method: event.method,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onClearingDateChanged(
    ClearingDateChangedEvent event,
    Emitter<LandClearingState> emit,
  ) {
    final currentState = state;
    if (currentState is LandClearingFormState) {
      final updatedRecord = currentState.record.copyWith(
        clearingDate: event.clearingDate,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onNotesChanged(
    LandClearingNotesChangedEvent event,
    Emitter<LandClearingState> emit,
  ) {
    final currentState = state;
    if (currentState is LandClearingFormState) {
      final updatedRecord = currentState.record.copyWith(
        notes: event.notes.isNotEmpty ? event.notes : null,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  Future<void> _onSaveRecord(
    SaveLandClearingRecordEvent event,
    Emitter<LandClearingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LandClearingFormState) return;

    emit(currentState.copyWith(isSaving: true, clearError: true));

    try {
      await _repository.saveLandClearingRecord(currentState.record);
      emit(
        currentState.copyWith(
          isSaving: false,
          isSaved: true,
          hasUnsavedChanges: false,
          successMessage: 'Data land clearing berhasil disimpan!',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          errorMessage: 'Gagal menyimpan data land clearing: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteRecord(
    DeleteLandClearingRecordEvent event,
    Emitter<LandClearingState> emit,
  ) async {
    try {
      await _repository.deleteLandClearingRecord(event.recordId);

      final currentState = state;
      if (currentState is LandClearingRecordsLoaded) {
        // Reload with same filters
        add(
          LoadLandClearingRecordsEvent(
            siteId: currentState.siteId,
            zoneId: currentState.zoneId,
          ),
        );
      }
    } catch (e) {
      emit(
        LandClearingError(
          'Gagal menghapus data land clearing: ${e.toString()}',
        ),
      );
    }
  }
}
