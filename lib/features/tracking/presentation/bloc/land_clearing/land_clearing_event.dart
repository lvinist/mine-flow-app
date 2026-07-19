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

/// Event fired when cleared area (m²) changes in the form.
class AreaClearedChangedEvent extends LandClearingEvent {
  final double areaClearedM2;

  const AreaClearedChangedEvent(this.areaClearedM2);

  @override
  List<Object?> get props => [areaClearedM2];
}

/// Event fired when clearing method selection changes.
class ClearingMethodChangedEvent extends LandClearingEvent {
  final String? clearingMethod;

  const ClearingMethodChangedEvent(this.clearingMethod);

  @override
  List<Object?> get props => [clearingMethod];
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
