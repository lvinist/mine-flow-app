import 'package:proj4dart/proj4dart.dart' as proj4;

/// Result of a UTM to geographic coordinate conversion.
class LatLonResult {
  /// Latitude in decimal degrees (WGS84).
  final double latitude;

  /// Longitude in decimal degrees (WGS84).
  final double longitude;

  const LatLonResult({required this.latitude, required this.longitude});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLonResult &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'LatLonResult(latitude: $latitude, longitude: $longitude)';
}

/// Coordinate Reference System (CRS) conversion utilities for mine-flow.
///
/// Provides methods to convert UTM (Universal Transverse Mercator) coordinates
/// to geographic coordinates (latitude/longitude) in WGS84 datum.
///
/// ## Supported CRS identifiers
/// - `'UTM Zone <number><hemisphere>'` — e.g. `'UTM Zone 51S'` for UTM Zone 51 South
/// - `'EPSG:<code>'` — arbitrary EPSG codes supported by proj4dart
///
/// ## Usage
/// ```dart
/// final result = CrsUtils.utmToLatLon(
///   northing: 9_200_000.0,
///   easting: 700_000.0,
///   crsIdentifier: 'UTM Zone 51S',
/// );
/// print('${result.latitude}, ${result.longitude}');
/// ```
class CrsUtils {
  CrsUtils._();

  /// The WGS84 geographic coordinate system projection string.
  static const String _wgs84Proj = '+proj=longlat +datum=WGS84 +no_defs';

  /// Registry of known UTM projection definitions keyed by identifier.
  ///
  /// Each entry maps a human-readable identifier (e.g. `'UTM Zone 51S'`)
  /// to its proj4 definition string.
  static final Map<String, String> _utmDefinitions = () {
    final map = <String, String>{};
    // Generate all UTM zones (1–60) for both North and South hemispheres.
    for (int zone = 1; zone <= 60; zone++) {
      final zoneStr = zone.toString().padLeft(2, '0');
      // Northern hemisphere
      map['UTM Zone ${zone}N'] =
          '+proj=utm +zone=$zoneStr +datum=WGS84 +units=m +no_defs';
      // Southern hemisphere
      map['UTM Zone ${zone}S'] =
          '+proj=utm +zone=$zoneStr +south +datum=WGS84 +units=m +no_defs';
    }
    return map;
  }();

  /// Maps EPSG codes to their proj4 definition strings for known UTM zones.
  static final Map<String, String> _epsgDefinitions = () {
    final map = <String, String>{};
    // Northern hemisphere UTM zones: EPSG:32601–32660
    for (int zone = 1; zone <= 60; zone++) {
      final epsgCode = (32600 + zone).toString();
      final zoneStr = zone.toString().padLeft(2, '0');
      map['EPSG:$epsgCode'] =
          '+proj=utm +zone=$zoneStr +datum=WGS84 +units=m +no_defs';
    }
    // Southern hemisphere UTM zones: EPSG:32701–32760
    for (int zone = 1; zone <= 60; zone++) {
      final epsgCode = (32700 + zone).toString();
      final zoneStr = zone.toString().padLeft(2, '0');
      map['EPSG:$epsgCode'] =
          '+proj=utm +zone=$zoneStr +south +datum=WGS84 +units=m +no_defs';
    }
    return map;
  }();

  /// Returns the proj4 definition string for the given [crsIdentifier].
  ///
  /// Supports:
  /// - `'UTM Zone <number><hemisphere>'` (e.g. `'UTM Zone 51S'`, `'UTM Zone 30N'`)
  /// - `'EPSG:<code>'` (e.g. `'EPSG:32751'` for UTM Zone 51S)
  ///
  /// Throws [ArgumentError] if the identifier is not recognised.
  static String _projDefinitionFor(String crsIdentifier) {
    // Check pre-built UTM definitions first.
    final utmDef = _utmDefinitions[crsIdentifier];
    if (utmDef != null) return utmDef;

    // Check EPSG definitions.
    final epsgDef = _epsgDefinitions[crsIdentifier.toUpperCase()];
    if (epsgDef != null) return epsgDef;

    throw ArgumentError(
      'Unknown CRS identifier: "$crsIdentifier". '
      'Supported formats: "UTM Zone <N>S" (e.g. "UTM Zone 51S") or "EPSG:<code>" '
      '(e.g. "EPSG:32751" for UTM Zone 51S).',
    );
  }

  /// Converts UTM coordinates (northing, easting) to geographic coordinates
  /// (latitude, longitude) in WGS84 datum.
  ///
  /// Parameters:
  /// - [northing]: The UTM northing value in metres.
  /// - [easting]: The UTM easting value in metres.
  /// - [crsIdentifier]: A recognised CRS identifier (see [CrsUtils] class docs).
  ///
  /// Returns a [LatLonResult] with latitude and longitude in decimal degrees.
  ///
  /// Throws [ArgumentError] if the CRS identifier is not supported.
  /// Throws [proj4.ProjectionException] if the projection transformation fails.
  static LatLonResult utmToLatLon({
    required double northing,
    required double easting,
    required String crsIdentifier,
  }) {
    final sourceProjDef = _projDefinitionFor(crsIdentifier);
    final sourceProj = proj4.Projection.parse(sourceProjDef);
    final wgs84Proj = proj4.Projection.parse(_wgs84Proj);

    // Transform the point from source CRS to WGS84.
    final sourcePoint = proj4.Point(x: easting, y: northing);
    final transformed = sourceProj.transform(wgs84Proj, sourcePoint);

    return LatLonResult(latitude: transformed.y, longitude: transformed.x);
  }

  /// Converts geographic coordinates (latitude, longitude) to UTM coordinates.
  ///
  /// Parameters:
  /// - [latitude]: Latitude in decimal degrees (WGS84).
  /// - [longitude]: Longitude in decimal degrees (WGS84).
  /// - [crsIdentifier]: The target UTM zone identifier (e.g. `'UTM Zone 51S'`).
  ///
  /// Returns a [NorthingEastingResult] with northing and easting in metres.
  ///
  /// Throws [ArgumentError] if the CRS identifier is not supported.
  /// Throws [proj4.ProjectionException] if the projection transformation fails.
  static NorthingEastingResult latLonToUtm({
    required double latitude,
    required double longitude,
    required String crsIdentifier,
  }) {
    final targetProjDef = _projDefinitionFor(crsIdentifier);
    final targetProj = proj4.Projection.parse(targetProjDef);
    final wgs84Proj = proj4.Projection.parse(_wgs84Proj);

    // Transform the point from WGS84 to the target UTM zone.
    final sourcePoint = proj4.Point(x: longitude, y: latitude);
    final transformed = wgs84Proj.transform(targetProj, sourcePoint);

    return NorthingEastingResult(
      northing: transformed.y,
      easting: transformed.x,
    );
  }
}

/// Result of a geographic to UTM coordinate conversion.
class NorthingEastingResult {
  /// Northing in metres.
  final double northing;

  /// Easting in metres.
  final double easting;

  const NorthingEastingResult({required this.northing, required this.easting});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NorthingEastingResult &&
          northing == other.northing &&
          easting == other.easting;

  @override
  int get hashCode => Object.hash(northing, easting);

  @override
  String toString() =>
      'NorthingEastingResult(northing: $northing, easting: $easting)';
}
