import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote datasource for fetching aggregated report data from Supabase.
///
/// Queries existing tables (attendance_records, cut_fill_records, inventory_items)
/// with date range and zone filters. Does not create new database tables.
class ReportingRemoteDataSource {
  final SupabaseClient supabaseClient;

  ReportingRemoteDataSource({required this.supabaseClient});

  /// Fetches attendance records joined with user names for the given filters.
  ///
  /// Queries the `attendance_records` table with a join to `users` for names.
  /// Returns raw JSON maps with: user_name, date, status, check_in, check_out, overtime_hours.
  Future<List<Map<String, dynamic>>> fetchAttendanceData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  }) async {
    try {
      final response = await supabaseClient
          .from('attendance_records')
          .select('*, users!inner(full_name)')
          .eq('site_id', siteId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .filter('deleted_at', 'is', null)
          .order('date', ascending: true);

      return response.map<Map<String, dynamic>>((row) {
        return {
          'user_name': row['users']?['full_name'] ?? 'Tidak Diketahui',
          'date': row['date'],
          'status': row['status'] ?? 'unknown',
          'check_in': row['check_in_time'],
          'check_out': row['check_out_time'],
          'overtime_hours': row['overtime_hours'] ?? 0.0,
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches cut/fill volume records joined with zone names for the given filters.
  ///
  /// Queries the `cut_fill_records` table with a join to `zones` for zone names.
  /// Returns raw JSON maps with: zone_name, measurement_date, cut_volume_m3,
  /// fill_volume_m3, net_volume_m3, measured_by.
  Future<List<Map<String, dynamic>>> fetchCutFillData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  }) async {
    try {
      var query = supabaseClient
          .from('cut_fill_records')
          .select('*, zones!inner(name, category)')
          .eq('site_id', siteId)
          .gte('measurement_date', startDate.toIso8601String())
          .lte('measurement_date', endDate.toIso8601String());

      if (zoneId != null) {
        query = query.eq('zone_id', zoneId);
      }

      final response = await query
          .filter('deleted_at', 'is', null)
          .order('measurement_date', ascending: true);

      return response.map<Map<String, dynamic>>((row) {
        final cutVol = (row['cut_volume_m3'] as num?)?.toDouble() ?? 0.0;
        final fillVol = (row['fill_volume_m3'] as num?)?.toDouble() ?? 0.0;
        return {
          'zone_name':
              '${row['zones']?['category'] ?? ''} - ${row['zones']?['name'] ?? ''}',
          'measurement_date': row['measurement_date'],
          'cut_volume_m3': cutVol,
          'fill_volume_m3': fillVol,
          'net_volume_m3': cutVol - fillVol,
          'measured_by': row['measured_by'],
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches current inventory items for the given site.
  ///
  /// Queries the `inventory_items` table.
  /// Returns raw JSON maps with: item_name, category, quantity, unit,
  /// minimum_stock, last_updated.
  Future<List<Map<String, dynamic>>> fetchInventoryData({
    required String siteId,
  }) async {
    try {
      final response = await supabaseClient
          .from('inventory_items')
          .select()
          .eq('site_id', siteId)
          .filter('deleted_at', 'is', null)
          .order('name', ascending: true);

      return response.map<Map<String, dynamic>>((row) {
        return {
          'item_name': row['name'] ?? 'Tidak Diketahui',
          'category': row['category'] ?? '-',
          'quantity': (row['quantity'] as num?)?.toDouble() ?? 0.0,
          'unit': row['unit'] ?? '-',
          'minimum_stock': (row['minimum_stock'] as num?)?.toDouble() ?? 0.0,
          'last_updated': row['updated_at'],
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
