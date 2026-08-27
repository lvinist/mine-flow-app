import 'package:equatable/equatable.dart';

/// Domain entity representing a survey control point (Benchmark).
///
/// Benchmarks are fixed reference points with known coordinates used in
/// surveying and mining operations. They support offline creation in the
/// field via UUID primary keys (see Doc 04 — Data Model, Ownership & Retention).
///
/// Fields:
/// - [id]: UUID primary key, generated client-side for offline-first support.
/// - [bmId]: Natural identifier (e.g. "BM-001"), assigned by the surveyor.
/// - [northing]: UTM northing value in metres.
/// - [easting]: UTM easting value in metres.
/// - [orthoHeight]: Orthometric height (elevation above geoid) in metres.
/// - [code]: Classification code for the benchmark.
/// - [orde]: Order/grade of the benchmark (e.g. "1st Order", "2nd Order").
/// - [geom]: PostGIS geometry string (e.g. "POINT(x y)"), nullable for offline records.
/// - [latitude]: WGS84 latitude in decimal degrees (auto-computed from UTM).
/// - [longitude]: WGS84 longitude in decimal degrees (auto-computed from UTM).
/// - [crsIdentifier]: Coordinate Reference System (e.g. "UTM Zone 51S") used to
///   derive lat/lon. Persisted (CF-033) so reopening does not re-derive from a
///   wrong default.
/// - [ellipsHeight]: Ellipsoidal height (height above ellipsoid) in metres.
/// - [status]: Lifecycle status (e.g. "active", "destroyed", "replaced").
class Benchmark extends Equatable {
  final String id;
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

  const Benchmark({
    required this.id,
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

  /// Creates a copy of this [Benchmark] with the given fields replaced.
  Benchmark copyWith({
    String? id,
    String? bmId,
    double? northing,
    double? easting,
    double? orthoHeight,
    String? code,
    String? orde,
    dynamic geom,
    double? latitude,
    double? longitude,
    String? crsIdentifier,
    double? ellipsHeight,
    String? status,
  }) {
    return Benchmark(
      id: id ?? this.id,
      bmId: bmId ?? this.bmId,
      northing: northing ?? this.northing,
      easting: easting ?? this.easting,
      orthoHeight: orthoHeight ?? this.orthoHeight,
      code: code ?? this.code,
      orde: orde ?? this.orde,
      geom: geom ?? this.geom,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      crsIdentifier: crsIdentifier ?? this.crsIdentifier,
      ellipsHeight: ellipsHeight ?? this.ellipsHeight,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bmId,
    northing,
    easting,
    orthoHeight,
    code,
    orde,
    geom,
    latitude,
    longitude,
    crsIdentifier,
    ellipsHeight,
    status,
  ];
}
