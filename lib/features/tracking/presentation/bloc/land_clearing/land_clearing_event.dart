import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

/// Abstract base class for all land clearing tracking BLoC events.
abstract class LandClearingEvent extends Equatable {
  const LandClearingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the list of land clearing records with optional filters.
class LoadLandClearingRecordsEvent extends LandClearingEvent {
  final String? siteId;
  final String? zoneId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadLandClearingRecordsEvent({
    this.siteId,
    this.zoneId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [siteId, zoneId, startDate, endDate];
}

/// Event to initialize or load a land clearing form state for creating/editing.
class InitializeLandClearingFormEvent extends LandClearingEvent {
  final String siteId;
  final String zoneId;
  final String foremanId;
  final LandClearingRecord? existingRecord;
  final String? dailyLogId;

  const InitializeLandClearingFormEvent({
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

/// Event fired when operational zone changes in the form.
class ZoneChangedEvent extends LandClearingEvent {
  final String zoneId;

  const ZoneChangedEvent(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

/// Event fired when plan area (m²) changes in the form.
class PlanAreaChangedEvent extends LandClearingEvent {
  final double planArea;

  const PlanAreaChangedEvent(this.planArea);

  @override
  List<Object?> get props => [planArea];
}

/// Event fired when actual area (m²) changes in the form.
class ActualAreaChangedEvent extends LandClearingEvent {
  final double actualArea;

  const ActualAreaChangedEvent(this.actualArea);

  @override
  List<Object?> get props => [actualArea];
}

/// Event fired when clearing method selection changes.
class MethodChangedEvent extends LandClearingEvent {
  final String? method;

  const MethodChangedEvent(this.method);

  @override
  List<Object?> get props => [method];
}

/// Event fired when clearing date changes.
class ClearingDateChangedEvent extends LandClearingEvent {
  final DateTime clearingDate;

  const ClearingDateChangedEvent(this.clearingDate);

  @override
  List<Object?> get props => [clearingDate];
}

/// Event fired when terrain notes text changes.
class LandClearingNotesChangedEvent extends LandClearingEvent {
  final String notes;

  const LandClearingNotesChangedEvent(this.notes);

  @override
  List<Object?> get props => [notes];
}

/// Event to save a land clearing record.
class SaveLandClearingRecordEvent extends LandClearingEvent {
  const SaveLandClearingRecordEvent();
}

/// Event to delete a land clearing record.
class DeleteLandClearingRecordEvent extends LandClearingEvent {
  final String recordId;

  const DeleteLandClearingRecordEvent(this.recordId);

  @override
  List<Object?> get props => [recordId];
}
