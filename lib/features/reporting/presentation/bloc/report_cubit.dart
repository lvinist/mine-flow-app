import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/core/error/failures.dart';
import 'package:mine_flow/features/reporting/domain/entities/date_range_filter.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_request.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_state.dart';
import 'package:uuid/uuid.dart';

/// Cubit managing report generation state and configuration.
///
/// Tracks the selected report type, date range, and optional zone filter,
/// and exposes [generateReport] to produce a PDF via [ReportingRepository].
class ReportCubit extends Cubit<ReportState> {
  final ReportingRepository _repository;

  ReportType? _selectedType;
  DateRangeFilter _dateRange = DateRangeFilter.currentWeek();
  String? _zoneId;

  ReportCubit({required this._repository}) : super(const ReportInitial());

  /// The currently selected date range.
  DateRangeFilter get currentRange => _dateRange;

  /// The currently selected optional zone filter (null = all zones).
  String? get currentZoneId => _zoneId;

  /// Selects a report type and resets back to [ReportInitial].
  void selectReportType(ReportType type) {
    _selectedType = type;
    emit(const ReportInitial());
  }

  /// Updates the date range filter.
  /// Resets to [ReportInitial] unless currently loading.
  void setDateRange(DateRangeFilter range) {
    _dateRange = range;
    if (state is! ReportLoading) emit(const ReportInitial());
  }

  /// Updates the optional zone filter.
  /// Resets to [ReportInitial] unless currently loading.
  void setZoneFilter(String? zoneId) {
    _zoneId = zoneId;
    if (state is! ReportLoading) emit(const ReportInitial());
  }

  /// Resets the state back to [ReportInitial] (e.g. for "Buat Ulang" action).
  void resetReport() {
    emit(const ReportInitial());
  }

  /// Generates a report with the current configuration.
  ///
  /// Emits [ReportLoading] while in progress, then either [ReportSuccess]
  /// with the PDF result or [ReportError] with a user-facing message.
  Future<void> generateReport({required String siteId}) async {
    if (_selectedType == null) {
      emit(const ReportError('Pilih jenis laporan terlebih dahulu.'));
      return;
    }

    emit(const ReportLoading());

    try {
      final request = ReportRequest(
        id: const Uuid().v4(),
        reportType: _selectedType!,
        siteId: siteId,
        dateRange: _dateRange,
        zoneId: _zoneId,
        createdAt: DateTime.now(),
      );

      final result = await _repository.generateReport(request);
      emit(ReportSuccess(result));
    } catch (e) {
      if (e is ValidationFailure) {
        emit(ReportError(e.message));
      } else if (e is ServerFailure) {
        emit(ReportError(e.message));
      } else {
        emit(ReportError('Terjadi kesalahan yang tidak diketahui: $e'));
      }
    }
  }
}
