import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Abstract base class for all daily log BLoC events.
abstract class DailyLogEvent extends Equatable {
  const DailyLogEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load list of daily logs with optional filters.
class LoadDailyLogsListEvent extends DailyLogEvent {
  final DateTime? date;
  final String? siteId;
  final String? foremanId;
  final LogStatus? statusFilter;

  const LoadDailyLogsListEvent({
    this.date,
    this.siteId,
    this.foremanId,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [date, siteId, foremanId, statusFilter];
}

/// Event to initialize or load a daily log form state.
class InitializeDailyLogFormEvent extends DailyLogEvent {
  final String foremanId;
  final String siteId;
  final DateTime logDate;
  final DailyLog? existingLog;

  const InitializeDailyLogFormEvent({
    required this.foremanId,
    required this.siteId,
    required this.logDate,
    this.existingLog,
  });

  @override
  List<Object?> get props => [foremanId, siteId, logDate, existingLog];
}

/// Event fired when log date changes in form.
class LogDateChangedEvent extends DailyLogEvent {
  final DateTime date;

  const LogDateChangedEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event fired when zone selection changes.
class ZoneChangedEvent extends DailyLogEvent {
  final String? zoneId;

  const ZoneChangedEvent(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

/// Event fired when weather selection changes.
class WeatherChangedEvent extends DailyLogEvent {
  final String? weather;

  const WeatherChangedEvent(this.weather);

  @override
  List<Object?> get props => [weather];
}

/// Event fired when work summary text changes.
class SummaryChangedEvent extends DailyLogEvent {
  final String summary;

  const SummaryChangedEvent(this.summary);

  @override
  List<Object?> get props => [summary];
}

/// Event fired when operational notes text changes.
class NotesChangedEvent extends DailyLogEvent {
  final String notes;

  const NotesChangedEvent(this.notes);

  @override
  List<Object?> get props => [notes];
}

/// Event to auto-save draft log locally.
class AutoSaveDraftEvent extends DailyLogEvent {
  const AutoSaveDraftEvent();
}

/// Event to submit daily log.
class SubmitDailyLogEvent extends DailyLogEvent {
  const SubmitDailyLogEvent();
}

/// Event to approve daily log (supervisor action).
class ApproveDailyLogEvent extends DailyLogEvent {
  final String logId;
  final String approvedBy;

  const ApproveDailyLogEvent({required this.logId, required this.approvedBy});

  @override
  List<Object?> get props => [logId, approvedBy];
}

/// Event to delete a daily log.
class DeleteDailyLogEvent extends DailyLogEvent {
  final String logId;

  const DeleteDailyLogEvent(this.logId);

  @override
  List<Object?> get props => [logId];
}
