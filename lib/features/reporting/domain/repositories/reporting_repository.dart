import 'package:mine_flow/features/reporting/domain/entities/report_request.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_result.dart';

/// Repository interface for the reporting feature.
///
/// Defines the contract for fetching aggregated data and generating reports.
/// The implementation queries existing Supabase tables (attendance_records,
/// cut_fill_records, inventory_items) and delegates PDF generation to PdfService.
abstract class ReportingRepository {
  /// Generates a complete report (data fetch + PDF generation) for the given request.
  ///
  /// Returns a [ReportResult] containing the PDF bytes and metadata.
  /// Throws [ServerFailure] if the Supabase query fails.
  /// Throws [ValidationFailure] if the request parameters are invalid.
  Future<ReportResult> generateReport(ReportRequest request);

  /// Fetches raw attendance data for the given site, date range, and optional zone.
  ///
  /// Returns a list of maps with keys: user_name, date, status, check_in, check_out, overtime_hours.
  Future<List<Map<String, dynamic>>> fetchAttendanceData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  });

  /// Fetches raw cut/fill volume data for the given site, date range, and optional zone.
  ///
  /// Returns a list of maps with keys: zone_name, measurement_date, cut_volume_m3,
  /// fill_volume_m3, net_volume_m3, measured_by.
  Future<List<Map<String, dynamic>>> fetchCutFillData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  });

  /// Fetches raw inventory data for the given site.
  ///
  /// Returns a list of maps with keys: item_name, category, quantity, unit,
  /// minimum_stock, last_updated.
  Future<List<Map<String, dynamic>>> fetchInventoryData({
    required String siteId,
  });

  /// Fetches daily field logs for the given site, date range, and optional zone.
  Future<List<Map<String, dynamic>>> fetchDailyLogData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  });

  /// Fetches land clearing records for the given site, date range, and optional zone.
  Future<List<Map<String, dynamic>>> fetchLandClearingData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  });

  /// Fetches equipment SOP inspection records for the given site and date range.
  Future<List<Map<String, dynamic>>> fetchEquipmentCheckData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetches benchmark database records for the given site.
  Future<List<Map<String, dynamic>>> fetchBenchmarkData({
    required String siteId,
  });
}
