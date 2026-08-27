/// Enumeration of supported report types in the reporting feature.
///
/// Each report type maps to a specific data source and PDF layout.
enum ReportType {
  /// Crew attendance & overtime report.
  /// Data source: attendance_records table.
  attendance('Laporan Kehadiran', 'attendance_records'),

  /// Cut/fill volume report (weekly, monthly, YTD, PTD).
  /// Data source: cut_fill_records table.
  cutFill('Laporan Volume Cut/Fill', 'cut_fill_records'),

  /// Inventory tracking report.
  /// Data source: inventory_items table.
  inventory('Laporan Inventaris', 'inventory_items'),

  /// Daily structured field log report (CF-025).
  /// Data source: daily_logs table.
  dailyLog('Laporan Log Harian', 'daily_logs'),

  /// Land clearing area report (CF-026).
  /// Data source: land_clearing_records table.
  landClearing('Laporan Land Clearing', 'land_clearing_records'),

  /// Equipment SOP inspection report (CF-027).
  /// Data source: equipment_checks table.
  equipmentCheck('Laporan Inspeksi Peralatan', 'equipment_checks'),

  /// Benchmark database report (CF-028).
  /// Data source: benchmarks table.
  benchmark('Laporan Benchmark', 'benchmarks');

  const ReportType(this.displayName, this.tableName);

  /// Indonesian display name for UI.
  final String displayName;

  /// Supabase table name for data queries.
  final String tableName;
}
