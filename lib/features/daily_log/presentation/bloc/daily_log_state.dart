import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';

/// Abstract base class for all daily log BLoC states.
abstract class DailyLogState extends Equatable {
  const DailyLogState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class DailyLogInitial extends DailyLogState {
  const DailyLogInitial();
}

/// Loading state while fetching or saving log data.
class DailyLogLoading extends DailyLogState {
  const DailyLogLoading();
}

/// State representing loaded history list of daily logs, extended for the
/// STEP-55.6 role-aware review workflow (spec §4.5 items 1–4).
class DailyLogsLoaded extends DailyLogState {
  final List<DailyLog> logs;
  final DateTime? selectedDate;
  final String? siteId;
  final LogStatus? statusFilter;

  /// Active review tab; the visible list is the tab × filter intersection.
  final DailyLogReviewTab activeTab;

  /// Per-tab counts for the tab strip (spec §4.5 item 1: each tab has a
  /// count). Derived from the full unfiltered-by-tab load so the counts
  /// remain meaningful while another tab is active.
  final Map<DailyLogReviewTab, int> tabCounts;

  /// Data filters from the popover (spec §4.5 item 2): zone + foreman;
  /// `selectedDate` doubles as the date filter.
  final String? zoneFilter;
  final String? foremanFilter;

  /// Supervisor approval in flight (spec §4.5 item 4): the log being
  /// approved right now, so cards can show progress and reject duplicate
  /// taps on the same record.
  final String? approvingLogId;

  const DailyLogsLoaded({
    required this.logs,
    this.selectedDate,
    this.siteId,
    this.statusFilter,
    this.activeTab = DailyLogReviewTab.all,
    this.tabCounts = const {},
    this.zoneFilter,
    this.foremanFilter,
    this.approvingLogId,
  });

  /// Count for one tab from the last full load.
  int countFor(DailyLogReviewTab tab) => tabCounts[tab] ?? 0;

  DailyLogsLoaded copyWith({
    List<DailyLog>? logs,
    DateTime? selectedDate,
    String? siteId,
    LogStatus? statusFilter,
    bool clearStatusFilter = false,
    DailyLogReviewTab? activeTab,
    Map<DailyLogReviewTab, int>? tabCounts,
    String? zoneFilter,
    bool clearZoneFilter = false,
    String? foremanFilter,
    bool clearForemanFilter = false,
    String? approvingLogId,
    bool clearApprovingLogId = false,
  }) {
    return DailyLogsLoaded(
      logs: logs ?? this.logs,
      selectedDate: selectedDate ?? this.selectedDate,
      siteId: siteId ?? this.siteId,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      activeTab: activeTab ?? this.activeTab,
      tabCounts: tabCounts ?? this.tabCounts,
      zoneFilter: clearZoneFilter ? null : (zoneFilter ?? this.zoneFilter),
      foremanFilter: clearForemanFilter
          ? null
          : (foremanFilter ?? this.foremanFilter),
      approvingLogId: clearApprovingLogId
          ? null
          : (approvingLogId ?? this.approvingLogId),
    );
  }

  @override
  List<Object?> get props => [
    logs,
    selectedDate,
    siteId,
    statusFilter,
    activeTab,
    tabCounts,
    zoneFilter,
    foremanFilter,
    approvingLogId,
  ];
}

/// Form state managing editing, auto-draft saving, and submission of a daily log.
class DailyLogFormState extends DailyLogState {
  final DailyLog log;
  final bool isSavingDraft;
  final bool isSubmitting;
  final bool isSubmitted;
  final bool isSaved;
  final String? autoSaveStatusText;
  final String? errorMessage;
  final String? successMessage;
  final bool hasUnsavedChanges;

  const DailyLogFormState({
    required this.log,
    this.isSavingDraft = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.isSaved = false,
    this.autoSaveStatusText,
    this.errorMessage,
    this.successMessage,
    this.hasUnsavedChanges = false,
  });

  /// Whether a pending auto-save write is still in flight (spec §4.5 item 6:
  /// dismissal must flush/await it before closing).
  bool get isBusy => isSavingDraft || isSubmitting;

  DailyLogFormState copyWith({
    DailyLog? log,
    bool? isSavingDraft,
    bool? isSubmitting,
    bool? isSubmitted,
    bool? isSaved,
    String? autoSaveStatusText,
    String? errorMessage,
    String? successMessage,
    bool? hasUnsavedChanges,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return DailyLogFormState(
      log: log ?? this.log,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isSaved: isSaved ?? this.isSaved,
      autoSaveStatusText: autoSaveStatusText ?? this.autoSaveStatusText,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  @override
  List<Object?> get props => [
    log,
    isSavingDraft,
    isSubmitting,
    isSubmitted,
    isSaved,
    autoSaveStatusText,
    errorMessage,
    successMessage,
    hasUnsavedChanges,
  ];
}

/// Error state for failures.
class DailyLogError extends DailyLogState {
  final String message;

  const DailyLogError(this.message);

  @override
  List<Object?> get props => [message];
}
