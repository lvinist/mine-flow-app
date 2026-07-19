import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

/// Abstract base class for all land clearing BLoC states.
abstract class LandClearingState extends Equatable {
  const LandClearingState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class LandClearingInitial extends LandClearingState {
  const LandClearingInitial();
}

/// Loading state while fetching or saving land clearing data.
class LandClearingLoading extends LandClearingState {
  const LandClearingLoading();
}

/// State representing loaded list of land clearing records with aggregated summaries.
class LandClearingRecordsLoaded extends LandClearingState {
  final List<LandClearingRecord> records;
  final String? siteId;
  final String? zoneId;

  /// Cumulative cleared area across all loaded records.
  final double totalAreaClearedM2;

  const LandClearingRecordsLoaded({
    required this.records,
    this.siteId,
    this.zoneId,
    this.totalAreaClearedM2 = 0.0,
  });

  /// Converted total cleared area in Hectares.
  double get totalAreaClearedHa => totalAreaClearedM2 / 10000.0;

  LandClearingRecordsLoaded copyWith({
    List<LandClearingRecord>? records,
    String? siteId,
    String? zoneId,
    double? totalAreaClearedM2,
  }) {
    return LandClearingRecordsLoaded(
      records: records ?? this.records,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      totalAreaClearedM2: totalAreaClearedM2 ?? this.totalAreaClearedM2,
    );
  }

  @override
  List<Object?> get props => [records, siteId, zoneId, totalAreaClearedM2];
}

/// Form state managing editing of a land clearing measurement record.
class LandClearingFormState extends LandClearingState {
  final LandClearingRecord record;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;
  final String? successMessage;
  final bool hasUnsavedChanges;

  const LandClearingFormState({
    required this.record,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
    this.successMessage,
    this.hasUnsavedChanges = false,
  });

  LandClearingFormState copyWith({
    LandClearingRecord? record,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
    String? successMessage,
    bool? hasUnsavedChanges,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return LandClearingFormState(
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
class LandClearingError extends LandClearingState {
  final String message;

  const LandClearingError(this.message);

  @override
  List<Object?> get props => [message];
}
