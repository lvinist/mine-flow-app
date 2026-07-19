import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/reporting/domain/entities/date_range_filter.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';

/// Domain entity representing a request to generate a report.
///
/// Encapsulates all parameters needed to query data and produce a report.
class ReportRequest extends Equatable {
  /// Unique identifier for this request.
  final String id;

  /// Type of report to generate.
  final ReportType reportType;

  /// Site ID to filter data for (Phase 1: single site).
  final String siteId;

  /// Date range for the report data.
  final DateRangeFilter dateRange;

  /// Optional zone ID filter. If null, includes all zones.
  final String? zoneId;

  /// Timestamp when this request was created.
  final DateTime createdAt;

  const ReportRequest({
    required this.id,
    required this.reportType,
    required this.siteId,
    required this.dateRange,
    this.zoneId,
    required this.createdAt,
  });

  /// Creates a new [ReportRequest] with the given fields replaced.
  ReportRequest copyWith({
    String? id,
    ReportType? reportType,
    String? siteId,
    DateRangeFilter? dateRange,
    String? zoneId,
    DateTime? createdAt,
  }) {
    return ReportRequest(
      id: id ?? this.id,
      reportType: reportType ?? this.reportType,
      siteId: siteId ?? this.siteId,
      dateRange: dateRange ?? this.dateRange,
      zoneId: zoneId ?? this.zoneId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    reportType,
    siteId,
    dateRange,
    zoneId,
    createdAt,
  ];
}
