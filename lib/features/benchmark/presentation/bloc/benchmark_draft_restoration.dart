import 'dart:convert';

import 'package:mine_flow/features/benchmark/presentation/bloc/benchmark_bloc.dart';

/// Restorable snapshot of the benchmark form's editable ENTRY fields only.
///
/// Per 59.0 design §6: latitude/longitude/geom/id are NEVER snapshotted — they
/// are recomputed from the restored northing/easting/CRS via the existing 55.4
/// projection path on restore. The snapshot contains only the 8 ENTRY fields:
///   bmId, northing, easting, orthoHeight, ellipsHeight, code, orde,
///   crsIdentifier, status
///
/// CONTEXT/derived fields (id, latitude, longitude, geom, updatedAt) are
/// reloaded from the repository on restore — never snapshotted.
class BenchmarkDraftRestoration {
  const BenchmarkDraftRestoration({
    required this.bmId,
    required this.northing,
    required this.easting,
    required this.orthoHeight,
    required this.ellipsHeight,
    required this.code,
    required this.orde,
    required this.crsIdentifier,
    required this.status,
  });

  // ENTRY fields only — no lat/lon/geom/id
  final String bmId;
  final double northing;
  final double easting;
  final double orthoHeight;
  final double? ellipsHeight;
  final String? code;
  final String? orde;
  final String crsIdentifier;
  final String status;

  /// Captures editable ENTRY values without persisting success, errors,
  /// sync state, or computed lat/lon (per 55.4: lat/lon excluded).
  static String encode(BenchmarkFormState state) {
    return jsonEncode({
      'version': 1,
      'bmId': state.bmId,
      'northing': state.northing,
      'easting': state.easting,
      'orthoHeight': state.orthoHeight,
      'ellipsHeight': state.ellipsHeight,
      'code': state.code,
      'orde': state.orde,
      'crsIdentifier': state.crsIdentifier,
      'status': state.status,
    });
  }

  /// Strict version-gated decode → null on mismatch.
  /// Rejects malformed or version-mismatched data rather than manufacturing
  /// a partial draft. The caller is responsible for re-running projection
  /// re-validation after applying the restored values.
  ///
  /// Per 55.4: lat/lon are recomputed from the restored northing+easting+CRS
  /// via [CrsUtils.utmToLatLon] — never restored from the snapshot. If the
  /// projection fails, the re-validation (not this decode) surfaces the error.
  static BenchmarkDraftRestoration? decode(String? serialized) {
    if (serialized == null) return null;
    try {
      final data = jsonDecode(serialized);
      if (data is! Map<String, dynamic> || data['version'] != 1) return null;

      // Strict type validation for every ENTRY field.
      if (data['bmId'] is! String) return null;

      final northing = _decodeDouble(data['northing']);
      final easting = _decodeDouble(data['easting']);
      final orthoHeight = _decodeDouble(data['orthoHeight']);
      // northing/easting/orthoHeight are required (non-null) per design.
      if (northing == null || easting == null || orthoHeight == null) {
        return null;
      }

      final ellipsHeight = _decodeDouble(data['ellipsHeight']);
      final code = data['code'];
      if (code != null && code is! String) return null;

      final orde = data['orde'];
      if (orde != null && orde is! String) return null;

      if (data['crsIdentifier'] is! String) return null;
      if (data['status'] is! String) return null;

      return BenchmarkDraftRestoration(
        bmId: data['bmId'] as String,
        northing: northing,
        easting: easting,
        orthoHeight: orthoHeight,
        ellipsHeight: ellipsHeight,
        code: code as String?,
        orde: orde as String?,
        crsIdentifier: data['crsIdentifier'] as String,
        status: data['status'] as String,
      );
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static double? _decodeDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
