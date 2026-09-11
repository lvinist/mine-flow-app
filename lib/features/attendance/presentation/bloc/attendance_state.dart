import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Base class for attendance BLoC state.
abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state before data is loaded.
class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

/// Loading state while reading records.
class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

/// Loaded state containing records, filters, and summary metrics.
class AttendanceLoaded extends AttendanceState {
  final List<AttendanceRecord> records;
  final DateTime selectedDate;
  final String? siteId;
  final String searchQuery;
  final AttendanceStatus? statusFilter;
  final bool isSubmitting;
  final bool hasUnsavedChanges;
  final String? successMessage;

  const AttendanceLoaded({
    required this.records,
    required this.selectedDate,
    this.siteId,
    this.searchQuery = '',
    this.statusFilter,
    this.isSubmitting = false,
    this.hasUnsavedChanges = false,
    this.successMessage,
  });

  /// Filtered records based on [searchQuery] and [statusFilter].
  ///
  /// STEP-55.5: search matches the crew member's **name** as well as the
  /// user id and remarks — the list's search hint promises name search, and
  /// the roster cards lead with names (no UUID copy), so id-only matching
  /// would leave the most visible field unsearchable.
  List<AttendanceRecord> get filteredRecords {
    return records.where((r) {
      final query = searchQuery.toLowerCase();
      final matchesSearch =
          searchQuery.isEmpty ||
          r.userName?.toLowerCase().contains(query) == true ||
          r.userId.toLowerCase().contains(query) ||
          (r.remarks != null && r.remarks!.toLowerCase().contains(query));

      final matchesStatus = statusFilter == null || r.status == statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  /// Summary count of present crew.
  int get presentCount =>
      records.where((r) => r.status == AttendanceStatus.present).length;

  /// Summary count of absent crew.
  int get absentCount =>
      records.where((r) => r.status == AttendanceStatus.absent).length;

  /// Summary count of sick crew.
  int get sickCount =>
      records.where((r) => r.status == AttendanceStatus.sick).length;

  /// Summary count of leave crew.
  int get leaveCount =>
      records.where((r) => r.status == AttendanceStatus.leave).length;

  /// Total count of crew records.
  int get totalCount => records.length;

  AttendanceLoaded copyWith({
    List<AttendanceRecord>? records,
    DateTime? selectedDate,
    String? siteId,
    String? searchQuery,
    AttendanceStatus? statusFilter,
    bool clearStatusFilter = false,
    bool? isSubmitting,
    bool? hasUnsavedChanges,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return AttendanceLoaded(
      records: records ?? this.records,
      selectedDate: selectedDate ?? this.selectedDate,
      siteId: siteId ?? this.siteId,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    records,
    selectedDate,
    siteId,
    searchQuery,
    statusFilter,
    isSubmitting,
    hasUnsavedChanges,
    successMessage,
  ];
}

/// Error state when loading or saving fails.
class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
