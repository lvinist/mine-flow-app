import 'package:logging/logging.dart';
import 'package:mine_flow/core/error/failures.dart';
import 'package:mine_flow/core/services/pdf_service.dart';
import 'package:mine_flow/features/reporting/data/datasources/reporting_remote_datasource.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_request.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_result.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';

/// Implementation of [ReportingRepository] that fetches data from Supabase
/// via [ReportingRemoteDataSource] and generates PDFs via [PdfService].
class ReportingRepositoryImpl implements ReportingRepository {
  final ReportingRemoteDataSource _remoteDataSource;
  final PdfService _pdfService;
  static final Logger _logger = Logger('ReportingRepositoryImpl');

  ReportingRepositoryImpl({
    required this._remoteDataSource,
    required this._pdfService,
  });

  @override
  Future<ReportResult> generateReport(ReportRequest request) async {
    _logger.info('Generating report: ${request.reportType.displayName}');

    if (!request.dateRange.isValid) {
      throw const ValidationFailure('Rentang tanggal tidak valid.');
    }

    try {
      List<Map<String, dynamic>> data;
      String title;

      switch (request.reportType) {
        case ReportType.attendance:
          data = await fetchAttendanceData(
            siteId: request.siteId,
            startDate: request.dateRange.startDate,
            endDate: request.dateRange.endDate,
            zoneId: request.zoneId,
          );
          title = 'Laporan Kehadiran';
        case ReportType.cutFill:
          data = await fetchCutFillData(
            siteId: request.siteId,
            startDate: request.dateRange.startDate,
            endDate: request.dateRange.endDate,
            zoneId: request.zoneId,
          );
          title = 'Laporan Volume Cut/Fill';
        case ReportType.inventory:
          data = await fetchInventoryData(siteId: request.siteId);
          title = 'Laporan Inventaris';
      }

      final pdfBytes = await _pdfService.generatePdf(
        reportType: request.reportType,
        title: title,
        data: data,
        startDate: request.dateRange.startDate,
        endDate: request.dateRange.endDate,
      );

      return ReportResult(
        request: request,
        pdfBytes: pdfBytes,
        title: title,
        recordCount: data.length,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      if (e is Failure) rethrow;
      _logger.severe('Report generation failed', e);
      throw ServerFailure('Gagal membuat laporan: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttendanceData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  }) {
    return _remoteDataSource.fetchAttendanceData(
      siteId: siteId,
      startDate: startDate,
      endDate: endDate,
      zoneId: zoneId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCutFillData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  }) {
    return _remoteDataSource.fetchCutFillData(
      siteId: siteId,
      startDate: startDate,
      endDate: endDate,
      zoneId: zoneId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchInventoryData({
    required String siteId,
  }) {
    return _remoteDataSource.fetchInventoryData(siteId: siteId);
  }
}
