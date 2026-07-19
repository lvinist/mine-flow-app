import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_request.dart';

/// Domain entity representing the result of a generated report.
///
/// Contains the PDF bytes and metadata about the generated report.
class ReportResult extends Equatable {
  /// The original request that produced this result.
  final ReportRequest request;

  /// Generated PDF as raw bytes. Can be shared, printed, or saved.
  final Uint8List pdfBytes;

  /// Human-readable title for the report (used in PDF header and sharing).
  final String title;

  /// Number of data rows included in the report.
  final int recordCount;

  /// Timestamp when the report was generated.
  final DateTime generatedAt;

  const ReportResult({
    required this.request,
    required this.pdfBytes,
    required this.title,
    required this.recordCount,
    required this.generatedAt,
  });

  /// File name for saving/sharing the PDF.
  String get fileName =>
      '${request.reportType.tableName}_report_${generatedAt.toIso8601String().substring(0, 10)}.pdf';

  @override
  List<Object?> get props => [
    request,
    pdfBytes,
    title,
    recordCount,
    generatedAt,
  ];
}
