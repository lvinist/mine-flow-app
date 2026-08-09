import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';

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

/// State representing loaded history list of daily logs.
class DailyLogsLoaded extends DailyLogState {
  final List<DailyLog> logs;
  final DateTime? selectedDate;
  final String? siteId;
  final LogStatus? statusFilter;

  const DailyLogsLoaded({
    required this.logs,
    this.selectedDate,
    this.siteId,
    this.statusFilter,
  });

  DailyLogsLoaded copyWith({
    List<DailyLog>? logs,
    DateTime? selectedDate,
    String? siteId,
    LogStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return DailyLogsLoaded(
      logs: logs ?? this.logs,
      selectedDate: selectedDate ?? this.selectedDate,
      siteId: siteId ?? this.siteId,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
    );
  }

  @override
  List<Object?> get props => [logs, selectedDate, siteId, statusFilter];
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
