import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';

/// Abstract base class for all cut/fill tracking BLoC events.
abstract class CutFillEvent extends Equatable {
  const CutFillEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the list of cut/fill records with optional filters.
class LoadCutFillRecordsEvent extends CutFillEvent {
  final String? siteId;
  final String? zoneId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadCutFillRecordsEvent({
    this.siteId,
    this.zoneId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [siteId, zoneId, startDate, endDate];
}

/// Event to initialize or load a cut/fill form state for creating/editing.
class InitializeCutFillFormEvent extends CutFillEvent {
  final String siteId;
  final String zoneId;
  final String foremanId;
  final CutFillRecord? existingRecord;
  final String? dailyLogId;

  const InitializeCutFillFormEvent({
    required this.siteId,
    required this.zoneId,
    required this.foremanId,
    this.existingRecord,
    this.dailyLogId,
  });

  @override
  List<Object?> get props => [
    siteId,
    zoneId,
    foremanId,
    existingRecord,
    dailyLogId,
  ];
}

/// Event fired when cut volume changes in the form.
class CutVolumeChangedEvent extends CutFillEvent {
  final double cutVolumeM3;

  const CutVolumeChangedEvent(this.cutVolumeM3);

  @override
  List<Object?> get props => [cutVolumeM3];
}

/// Event fired when fill volume changes in the form.
class FillVolumeChangedEvent extends CutFillEvent {
  final double fillVolumeM3;

  const FillVolumeChangedEvent(this.fillVolumeM3);

  @override
  List<Object?> get props => [fillVolumeM3];
}

/// Event fired when elevation change value changes.
class ElevationChangeChangedEvent extends CutFillEvent {
  final double? elevationChange;

  const ElevationChangeChangedEvent(this.elevationChange);

  @override
  List<Object?> get props => [elevationChange];
}

/// Event fired when measurement date changes.
class MeasurementDateChangedEvent extends CutFillEvent {
  final DateTime measurementDate;

  const MeasurementDateChangedEvent(this.measurementDate);

  @override
  List<Object?> get props => [measurementDate];
}

/// Event fired when notes text changes.
class CutFillNotesChangedEvent extends CutFillEvent {
  final String notes;

  const CutFillNotesChangedEvent(this.notes);

  @override
  List<Object?> get props => [notes];
}

/// Event to save a cut/fill record (draft or final).
class SaveCutFillRecordEvent extends CutFillEvent {
  const SaveCutFillRecordEvent();
}

/// Event to delete a cut/fill record.
class DeleteCutFillRecordEvent extends CutFillEvent {
  final String recordId;

  const DeleteCutFillRecordEvent(this.recordId);

  @override
  List<Object?> get props => [recordId];
}
