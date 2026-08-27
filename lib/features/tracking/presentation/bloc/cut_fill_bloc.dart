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
///
/// v2: Uses bcmVolume/lcmVolume instead of cutVolumeM3/fillVolumeM3.
class CutFillBloc extends Bloc<CutFillEvent, CutFillState> {
  final TrackingRepository _repository;
  final Uuid _uuid;

  CutFillBloc({required this._repository, Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const CutFillInitial()) {
    on<LoadCutFillRecordsEvent>(_onLoadRecords);
    on<InitializeCutFillFormEvent>(_onInitializeForm);
    on<ZoneChangedEvent>(_onZoneChanged);
    on<BcmVolumeChangedEvent>(_onBcmVolumeChanged);
    on<LcmVolumeChangedEvent>(_onLcmVolumeChanged);
    on<MaterialTypeChangedEvent>(_onMaterialTypeChanged);
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

      final totalBcm = records.fold<double>(0.0, (sum, r) => sum + r.bcmVolume);
      final totalLcm = records.fold<double>(0.0, (sum, r) => sum + r.lcmVolume);
      // CF-014: net is the bank-equivalent volume (BCM + LCM/(1+swell)),
      // never `bcm - lcm` (two measurement bases, not cut vs fill).
      final totalNet = records.fold<double>(0.0, (sum, r) => sum + r.netVolume);

      emit(
        CutFillRecordsLoaded(
          records: records,
          siteId: event.siteId,
          zoneId: event.zoneId,
          totalCutM3: totalBcm,
          totalFillM3: totalLcm,
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
            bcmVolume: 0.0,
            lcmVolume: 0.0,
            measurementDate: DateTime.now(),
            measuredBy: event.foremanId,
            createdAt: DateTime.now(),
          );

      emit(CutFillFormState(record: record));
    } catch (e) {
      emit(CutFillError('Gagal inisialisasi form cut/fill: ${e.toString()}'));
    }
  }

  void _onZoneChanged(ZoneChangedEvent event, Emitter<CutFillState> emit) {
    final currentState = state;
    if (currentState is CutFillFormState) {
      final updatedRecord = currentState.record.copyWith(
        zoneId: event.zoneId,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onBcmVolumeChanged(
    BcmVolumeChangedEvent event,
    Emitter<CutFillState> emit,
  ) {
    final currentState = state;
    if (currentState is CutFillFormState) {
      final updatedRecord = currentState.record.copyWith(
        bcmVolume: event.bcmVolume,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onLcmVolumeChanged(
    LcmVolumeChangedEvent event,
    Emitter<CutFillState> emit,
  ) {
    final currentState = state;
    if (currentState is CutFillFormState) {
      final updatedRecord = currentState.record.copyWith(
        lcmVolume: event.lcmVolume,
        updatedAt: DateTime.now(),
      );
      emit(
        currentState.copyWith(record: updatedRecord, hasUnsavedChanges: true),
      );
    }
  }

  void _onMaterialTypeChanged(
    MaterialTypeChangedEvent event,
    Emitter<CutFillState> emit,
  ) {
    final currentState = state;
    if (currentState is CutFillFormState) {
      final updatedRecord = currentState.record.copyWith(
        materialType: event.materialType,
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
        clearElevationChange: event.elevationChange == null,
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
