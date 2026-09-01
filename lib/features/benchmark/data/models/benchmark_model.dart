import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';

/// Data model for [Benchmark] providing JSON serialization to/from Supabase.
///
/// Maps between `snake_case` (database columns) and `camelCase` (Dart conventions).
/// Also provides Hive-friendly JSON serialization for offline caching.
class BenchmarkModel {
  final String id;

  /// Site the benchmark belongs to (`benchmarks.site_id`, NOT NULL).
  ///
  /// Defaults to [defaultSiteId] for locally created rows so a write never
  /// falls back to the schema's legacy `00000000-…-0001` column default
  /// (STEP-48.26 R-5 — new rows must exist under the settled site id).
  /// Deserialization always carries the row's real site through.
  final String siteId;
  final String bmId;
  final double northing;
  final double easting;
  final double orthoHeight;
  final String code;
  final String orde;
  final dynamic geom;
  final double latitude;
  final double longitude;
  final String crsIdentifier;
  final double ellipsHeight;
  final String status;

  const BenchmarkModel({
    required this.id,
    this.siteId = defaultSiteId,
    required this.bmId,
    required this.northing,
    required this.easting,
    required this.orthoHeight,
    required this.code,
    required this.orde,
    this.geom,
    required this.latitude,
    required this.longitude,
    this.crsIdentifier = 'UTM Zone 51S',
    required this.ellipsHeight,
    required this.status,
  });

  /// Factory constructor to deserialize from Supabase JSON (snake_case).
  factory BenchmarkModel.fromJson(Map<String, dynamic> json) {
    return BenchmarkModel(
      id: json['id'] as String,
      siteId: json['site_id'] as String? ?? defaultSiteId,
      bmId: json['bm_id'] as String,
      northing: (json['northing'] as num).toDouble(),
      easting: (json['easting'] as num).toDouble(),
      orthoHeight: (json['ortho_height'] as num).toDouble(),
      code: json['code'] as String,
      orde: json['orde'] as String,
      geom: json['geom'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      crsIdentifier: json['crs_identifier'] as String? ?? 'UTM Zone 51S',
      ellipsHeight: (json['ellips_height'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  /// Serializes to JSON map (snake_case) suitable for Supabase operations.
  ///
  /// `site_id` is always emitted: relying on the column default would place
  /// every app-created benchmark under the legacy seed site instead of
  /// [defaultSiteId] (STEP-48.26 R-5).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'bm_id': bmId,
      'northing': northing,
      'easting': easting,
      'ortho_height': orthoHeight,
      'code': code,
      'orde': orde,
      if (geom != null) 'geom': geom,
      'latitude': latitude,
      'longitude': longitude,
      'crs_identifier': crsIdentifier,
      'ellips_height': ellipsHeight,
      'status': status,
    };
  }

  /// Serializes to a JSON map suitable for Hive offline cache storage.
  /// Uses camelCase keys for consistency with Dart conventions.
  Map<String, dynamic> toHiveJson() {
    return {
      'id': id,
      'siteId': siteId,
      'bmId': bmId,
      'northing': northing,
      'easting': easting,
      'orthoHeight': orthoHeight,
      'code': code,
      'orde': orde,
      'geom': geom,
      'latitude': latitude,
      'longitude': longitude,
      'crsIdentifier': crsIdentifier,
      'ellipsHeight': ellipsHeight,
      'status': status,
    };
  }

  /// Factory constructor to deserialize from Hive JSON (camelCase).
  factory BenchmarkModel.fromHiveJson(Map<String, dynamic> json) {
    return BenchmarkModel(
      id: json['id'] as String,
      siteId: json['siteId'] as String? ?? defaultSiteId,
      bmId: json['bmId'] as String,
      northing: (json['northing'] as num).toDouble(),
      easting: (json['easting'] as num).toDouble(),
      orthoHeight: (json['orthoHeight'] as num).toDouble(),
      code: json['code'] as String,
      orde: json['orde'] as String,
      geom: json['geom'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      crsIdentifier: json['crsIdentifier'] as String? ?? 'UTM Zone 51S',
      ellipsHeight: (json['ellipsHeight'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  /// Converts this model to a domain [Benchmark].
  Benchmark toDomain() {
    return Benchmark(
      id: id,
      bmId: bmId,
      northing: northing,
      easting: easting,
      orthoHeight: orthoHeight,
      code: code,
      orde: orde,
      geom: geom,
      latitude: latitude,
      longitude: longitude,
      crsIdentifier: crsIdentifier,
      ellipsHeight: ellipsHeight,
      status: status,
    );
  }

  /// Factory constructor from a domain [Benchmark].
  factory BenchmarkModel.fromDomain(Benchmark entity) {
    return BenchmarkModel(
      id: entity.id,
      bmId: entity.bmId,
      northing: entity.northing,
      easting: entity.easting,
      orthoHeight: entity.orthoHeight,
      code: entity.code,
      orde: entity.orde,
      geom: entity.geom,
      latitude: entity.latitude,
      longitude: entity.longitude,
      crsIdentifier: entity.crsIdentifier,
      ellipsHeight: entity.ellipsHeight,
      status: entity.status,
    );
  }
}
