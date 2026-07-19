import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_state.dart';

/// BLoC handling state management for Cut/Fill volume tracking:
/// - List view with aggregated totals and filters
/// - Form creation and editing of measurement records
/// - Save and delete operations via repository
class CutFillBloc extends Bloc<CutFillEvent, CutFillState> {
  final TrackingRepository _repository;
  final Uuid _uuid;

  CutFillBloc({required this._repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const CutFillInitial()) {
    on<LoadCutFillRecordsEvent>(_onLoadRecords);
    on<InitializeCutFillFormEvent>(_onInitializeForm);
    on<CutVolumeChangedEvent>(_onCutVolumeChanged);
    on<FillVolumeChangedEvent>(_onFillVolumeChanged);
    on<ElevationChangeChangedEvent>(_onElevationChangeChanged);
    on<MeasurementDateChangedEvent>(_onMeasurementDateChanged);
    on<CutFillNotesChangedEvent>(_onNotesChanged);
    on<SaveCutFillRecordEvent>(_onSaveRecord);
    on<DeleteCutFillRecordEvent>(_onDeleteRecord);
  }

  Future<void> _onLoadRecords(
    LoadCutFillRecordsEvent event,
    Emitter<CutFillState> emit,
  ) async {
    emit(const CutFillLoading());
    try {
      final records = await _repository.getCutFillRecords(
        siteId: event.siteId,
        zoneId: event.zoneId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final totalCut = records.fold<double>(
        0.0,
        (sum, r) => sum + r.cutVolumeM3,
      );
      final totalFill = records.fold<double>(
        0.0,
        (sum, r) => sum + r.fillVolumeM3,
      );
      final totalNet = totalCut - totalFill;

      emit(
        CutFillRecordsLoaded(
          records: records,
          siteId: event.siteId,
          zoneId: event.zoneId,
          totalCutM3: totalCut,
          totalFillM3: totalFill,
          totalNetM3: totalNet,
        ),
      );
    } catch (e) {
      emit(CutFillError('Gagal memuat data cut/fill: ${e.toString()}'));
    }
  }

  Future<void> _onInitializeForm(
    InitializeCutFillFormEvent event,
    Emitter<CutFillState> emit,
  ) async {
    emit(const CutFillLoading());
    try {
      final record =
          event.existingRecord ??
          CutFillRecord(
            id: _uuid.v4(),
            siteId: event.siteId,
            zoneId: event.zoneId,
            dailyLogId: event.dailyLogId,
            cutVolumeM3: 0.0,
            fillVolumeM3: 0.0,
            measurementDate: DateTime.now(),
            measuredBy: event.foremanId,
            createdAt: DateTime.now(),
          );

      emit(CutFillFormState(record: record));
    } catch (e) {
      emit(CutFillError('Gagal inisialisasi form cut/fill: ${e.toString()}'));
    }
  }

  void _onCutVolumeChanged(
    CutVolumeChangedEvent event,
    Emitter<CutFillState> emit,
  ) {
    final currentState = state;
    if (currentState is CutFillFormState) {
      final updatedRecord = currentState.record.copyWith(
        cutVolumeM3: event.cutVolumeM3,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onFillVolumeChanged(
    FillVolumeChangedEvent event,
    Emitter<CutFillState> emit,
  ) {
    final currentState = state;
    if (currentState is CutFillFormState) {
      final updatedRecord = currentState.record.copyWith(
        fillVolumeM3: event.fillVolumeM3,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onElevationChangeChanged(
    ElevationChangeChangedEvent event,
    Emitter<CutFillState> emit,
  ) {
    final currentState = state;
    if (currentState is CutFillFormState) {
      final updatedRecord = currentState.record.copyWith(
        elevationChange: event.elevationChange,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onMeasurementDateChanged(
    MeasurementDateChangedEvent event,
    Emitter<CutFillState> emit,
  ) {
    final currentState = state;
    if (currentState is CutFillFormState) {
      final updatedRecord = currentState.record.copyWith(
        measurementDate: event.measurementDate,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onNotesChanged(
    CutFillNotesChangedEvent event,
    Emitter<CutFillState> emit,
  ) {
    final currentState = state;
    if (currentState is CutFillFormState) {
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
    SaveCutFillRecordEvent event,
    Emitter<CutFillState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CutFillFormState) return;

    emit(currentState.copyWith(isSaving: true, clearError: true));

    try {
      await _repository.saveCutFillRecord(currentState.record);
      emit(
        currentState.copyWith(
          isSaving: false,
          isSaved: true,
          hasUnsavedChanges: false,
          successMessage: 'Data cut/fill berhasil disimpan!',
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isSaving: false,
          errorMessage: 'Gagal menyimpan data cut/fill: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteRecord(
    DeleteCutFillRecordEvent event,
    Emitter<CutFillState> emit,
  ) async {
    try {
      await _repository.deleteCutFillRecord(event.recordId);

      final currentState = state;
      if (currentState is CutFillRecordsLoaded) {
        // Reload with same filters
        add(
          LoadCutFillRecordsEvent(
            siteId: currentState.siteId,
            zoneId: currentState.zoneId,
          ),
        );
      }
    } catch (e) {
      emit(CutFillError('Gagal menghapus data cut/fill: ${e.toString()}'));
    }
  }
}
