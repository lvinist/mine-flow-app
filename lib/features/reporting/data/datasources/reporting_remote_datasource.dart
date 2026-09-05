import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_flow/features/tracking/domain/entities/volume_normalizer.dart';

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
          .select('*, users!attendance_records_user_id_fkey(name)')
          .eq('site_id', siteId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .filter('deleted_at', 'is', null)
          .order('date', ascending: true);

      return response.map<Map<String, dynamic>>((row) {
        return {
          'user_name': row['users']?['name'] ?? 'Tidak Diketahui',
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
  ///
  /// **Presentation-map boundary (STEP-48.27).** The database columns are
  /// `bcm_volume` / `lcm_volume` (`20260723_step_33_1_data_model_polish.sql`
  /// dropped `cut_volume`/`fill_volume`); the returned keys
  /// `cut_volume_m3` / `fill_volume_m3` / `net_volume_m3` / `measurement_date`
  /// are report-facing names consumed by `PdfService`, NOT column names. Read
  /// the schema on the way in, keep the report contract on the way out.
  ///
  /// `net_volume_m3` is the **bank-equivalent** volume per ADR-0012
  /// (`bcm + lcm / (1 + swell)`), not `cut − fill`: BCM and LCM measure the
  /// same material on two different bases, so subtracting them is physically
  /// meaningless. This closes the second half of RISK-0014 — the first half
  /// (legacy column names) is the schema-key fix above.
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
          .gte('measured_at', startDate.toIso8601String())
          .lte('measured_at', endDate.toIso8601String());

      if (zoneId != null) {
        query = query.eq('zone_id', zoneId);
      }

      final response = await query
          .filter('deleted_at', 'is', null)
          .order('measured_at', ascending: true);

      return response.map<Map<String, dynamic>>((row) {
        final bcmVolume = (row['bcm_volume'] as num?)?.toDouble() ?? 0.0;
        final lcmVolume = (row['lcm_volume'] as num?)?.toDouble() ?? 0.0;
        return {
          'zone_name':
              '${row['zones']?['category'] ?? ''} - ${row['zones']?['name'] ?? ''}',
          'measurement_date': row['measured_at'],
          'cut_volume_m3': bcmVolume,
          'fill_volume_m3': lcmVolume,
          'net_volume_m3': VolumeNormalizer.bankEquivalent(
            bcm: bcmVolume,
            lcm: lcmVolume,
            materialType: row['material_type'] as String?,
          ),
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
          'minimum_stock': (row['min_threshold'] as num?)?.toDouble() ?? 0.0,
          'last_updated': row['updated_at'],
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches daily field logs for the given filters (CF-025).
  Future<List<Map<String, dynamic>>> fetchDailyLogData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  }) async {
    var query = supabaseClient
        .from('daily_logs')
        .select()
        .eq('site_id', siteId)
        .gte('log_date', startDate.toIso8601String())
        .lte('log_date', endDate.toIso8601String());

    if (zoneId != null) {
      query = query.eq('zone_id', zoneId);
    }

    final response = await query
        .filter('deleted_at', 'is', null)
        .order('log_date', ascending: true);

    return response.map<Map<String, dynamic>>((row) {
      return {
        'log_date': row['log_date'],
        'foreman_id': row['foreman_id'],
        'zone_id': row['zone_id'],
        'weather': row['weather'],
        'summary': row['summary'],
        'status': row['status'],
      };
    }).toList();
  }

  /// Fetches land clearing records for the given filters (CF-026).
  Future<List<Map<String, dynamic>>> fetchLandClearingData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
    String? zoneId,
  }) async {
    var query = supabaseClient
        .from('land_clearing_records')
        .select()
        .eq('site_id', siteId)
        .gte('cleared_at', startDate.toIso8601String())
        .lte('cleared_at', endDate.toIso8601String());

    if (zoneId != null) {
      query = query.eq('zone_id', zoneId);
    }

    final response = await query
        .filter('deleted_at', 'is', null)
        .order('cleared_at', ascending: true);

    return response.map<Map<String, dynamic>>((row) {
      return {
        'clearing_date': row['cleared_at'],
        'zone_id': row['zone_id'],
        'plan_area': (row['plan_area'] as num?)?.toDouble() ?? 0.0,
        'actual_area': (row['actual_area'] as num?)?.toDouble() ?? 0.0,
        'method': row['method'] ?? row['clearing_method'],
        'cleared_by': row['cleared_by'],
      };
    }).toList();
  }

  /// Fetches equipment SOP inspection records (CF-027).
  Future<List<Map<String, dynamic>>> fetchEquipmentCheckData({
    required String siteId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await supabaseClient
        .from('equipment_checks')
        .select()
        .eq('site_id', siteId)
        .gte('check_time', startDate.toIso8601String())
        .lte('check_time', endDate.toIso8601String())
        .filter('deleted_at', 'is', null)
        .order('check_time', ascending: true);

    return response.map<Map<String, dynamic>>((row) {
      return {
        'check_time': row['check_time'],
        'serial_number': row['serial_number'],
        'equipment_type': row['equipment_type'],
        'check_type': row['check_type'],
        // `status` is a PRESENTATION-MAP value, not a database column:
        // `equipment_checks` has only the boolean `is_operational`
        // (supabase/types/database.ts). Derive it exactly the way
        // `EquipmentCheckDto.fromJson` does so the report and the app agree on
        // one status vocabulary (CheckStatus: passed / failed / flagged).
        'status': (row['is_operational'] as bool? ?? true)
            ? 'passed'
            : 'flagged',
        'is_operational': row['is_operational'] ?? true,
        'foreman_id': row['foreman_id'],
      };
    }).toList();
  }

  /// Fetches benchmark database records (CF-028).
  Future<List<Map<String, dynamic>>> fetchBenchmarkData({
    required String siteId,
  }) async {
    final response = await supabaseClient
        .from('benchmarks')
        .select()
        .eq('site_id', siteId)
        .filter('deleted_at', 'is', null)
        .order('bm_id', ascending: true);

    return response.map<Map<String, dynamic>>((row) {
      return {
        'bm_id': row['bm_id'],
        'northing': (row['northing'] as num?)?.toDouble(),
        'easting': (row['easting'] as num?)?.toDouble(),
        'ortho_height': (row['ortho_height'] as num?)?.toDouble(),
        'ellips_height': (row['ellips_height'] as num?)?.toDouble(),
        'code': row['code'],
        'status': row['status'],
      };
    }).toList();
  }
}
