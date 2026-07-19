/// Enumeration of supported report types in the reporting feature.
///
/// Each report type maps to a specific data source and PDF layout.
enum ReportType {
  /// Crew attendance & overtime report.
  /// Data source: attendance_records table.
  attendance('Laporan Kehadiran', 'attendance'),

  /// Cut/fill volume report (weekly, monthly, YTD, PTD).
  /// Data source: cut_fill_records table.
  cutFill('Laporan Volume Cut/Fill', 'cut_fill'),

  /// Inventory tracking report.
  /// Data source: inventory_items table.
  inventory('Laporan Inventaris', 'inventory');

  const ReportType(this.displayName, this.tableName);

  /// Indonesian display name for UI.
  final String displayName;

  /// Supabase table name for data queries.
  final String tableName;
}
