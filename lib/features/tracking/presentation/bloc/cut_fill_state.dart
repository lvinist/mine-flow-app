import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';

/// Abstract base class for all cut/fill BLoC states.
abstract class CutFillState extends Equatable {
  const CutFillState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class CutFillInitial extends CutFillState {
  const CutFillInitial();
}

/// Loading state while fetching or saving cut/fill data.
class CutFillLoading extends CutFillState {
  const CutFillLoading();
}

/// State representing loaded list of cut/fill records.
class CutFillRecordsLoaded extends CutFillState {
  final List<CutFillRecord> records;
  final String? siteId;
  final String? zoneId;

  /// Aggregated totals across all loaded records.
  final double totalCutM3;
  final double totalFillM3;
  final double totalNetM3;

  const CutFillRecordsLoaded({
    required this.records,
    this.siteId,
    this.zoneId,
    this.totalCutM3 = 0.0,
    this.totalFillM3 = 0.0,
    this.totalNetM3 = 0.0,
  });

  CutFillRecordsLoaded copyWith({
    List<CutFillRecord>? records,
    String? siteId,
    String? zoneId,
    double? totalCutM3,
    double? totalFillM3,
    double? totalNetM3,
  }) {
    return CutFillRecordsLoaded(
      records: records ?? this.records,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      totalCutM3: totalCutM3 ?? this.totalCutM3,
      totalFillM3: totalFillM3 ?? this.totalFillM3,
      totalNetM3: totalNetM3 ?? this.totalNetM3,
    );
  }

  @override
  List<Object?> get props => [
    records,
    siteId,
    zoneId,
    totalCutM3,
    totalFillM3,
    totalNetM3,
  ];
}

/// Form state managing editing of a cut/fill measurement record.
class CutFillFormState extends CutFillState {
  final CutFillRecord record;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;
  final String? successMessage;
  final bool hasUnsavedChanges;

  const CutFillFormState({
    required this.record,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
    this.successMessage,
    this.hasUnsavedChanges = false,
  });

  CutFillFormState copyWith({
    CutFillRecord? record,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
    String? successMessage,
    bool? hasUnsavedChanges,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CutFillFormState(
      record: record ?? this.record,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  @override
  List<Object?> get props => [
    record,
    isSaving,
    isSaved,
    errorMessage,
    successMessage,
    hasUnsavedChanges,
  ];
}

/// Error state for failures.
class CutFillError extends CutFillState {
  final String message;

  const CutFillError(this.message);

  @override
  List<Object?> get props => [message];
}
