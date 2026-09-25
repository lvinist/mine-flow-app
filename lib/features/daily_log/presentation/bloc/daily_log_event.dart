import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

/// Abstract base class for all daily log BLoC events.
abstract class DailyLogEvent extends Equatable {
  const DailyLogEvent();

  @override
  List<Object?> get props => [];
}

/// Review-workflow tab (STEP-55.6 spec §4.5 item 1): tabs express workflow
/// status only — `Semua`, `Draft`, `Perlu Disetujui` (submitted),
/// `Disetujui` (approved).
enum DailyLogReviewTab { all, draft, needsApproval, approved }

/// Event to load list of daily logs with optional filters.
class LoadDailyLogsListEvent extends DailyLogEvent {
  final DateTime? date;
  final String? siteId;
  final String? foremanId;
  final LogStatus? statusFilter;
  final DailyLogReviewTab? tab;

  const LoadDailyLogsListEvent({
    this.date,
    this.siteId,
    this.foremanId,
    this.statusFilter,
    this.tab,
  });

  @override
  List<Object?> get props => [date, siteId, foremanId, statusFilter, tab];
}

/// Event selecting the active review tab (spec §4.5 item 1).
///
/// Role defaults are resolved by the screen: a foreman starts on `Draft`
/// (their own logs), a supervisor on `Perlu Disetujui` (site-wide submitted
/// queue). Switching tabs reloads the list for the tab's status while
/// preserving the other filters.
class SelectDailyLogTabEvent extends DailyLogEvent {
  final DailyLogReviewTab tab;

  const SelectDailyLogTabEvent(this.tab);

  @override
  List<Object?> get props => [tab];
}

/// Event applying the popover filters (date/zone/foreman; spec §4.5 item 2).
///
/// These are data filters, distinct from the workflow tab: applying them
/// preserves the active tab and reloads.
class ApplyDailyLogFiltersEvent extends DailyLogEvent {
  final DateTime? date;
  final String? zoneId;
  final String? foremanId;

  const ApplyDailyLogFiltersEvent({this.date, this.zoneId, this.foremanId});

  @override
  List<Object?> get props => [date, zoneId, foremanId];
}

/// Event to initialize or load a daily log form state.
class InitializeDailyLogFormEvent extends DailyLogEvent {
  final String foremanId;
  final String siteId;
  final DateTime logDate;
  final DailyLog? existingLog;
  final String? logId;

  const InitializeDailyLogFormEvent({
    required this.foremanId,
    required this.siteId,
    required this.logDate,
    this.existingLog,
    this.logId,
  });

  @override
  List<Object?> get props => [foremanId, siteId, logDate, existingLog, logId];
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

/// Event fired when the structured hazard assessment changes
/// (spec §4.5 item 7 — the foreman must answer the hazard question).
class HazardChangedEvent extends DailyLogEvent {
  final HazardAssessmentChange change;

  const HazardChangedEvent(this.change);

  @override
  List<Object?> get props => [change];
}

/// One discrete hazard-assessment edit, applied to the current
/// [HazardAssessment] (spec §4.5 item 7).
///
/// The shape mirrors the domain contract: state is one of
/// not-assessed / none / present; severity is meaningful only when present.
class HazardAssessmentChange {
  final HazardState? state;
  final HazardSeverity? severity;
  final String? notes;
  final String? correctiveAction;

  const HazardAssessmentChange({
    this.state,
    this.severity,
    this.notes,
    this.correctiveAction,
  });
}

/// Event to auto-save draft log locally.
class AutoSaveDraftEvent extends DailyLogEvent {
  const AutoSaveDraftEvent();
}

/// Event to submit daily log.
class SubmitDailyLogEvent extends DailyLogEvent {
  const SubmitDailyLogEvent();
}

/// Event to approve daily log (supervisor action, spec §4.5 item 4).
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
