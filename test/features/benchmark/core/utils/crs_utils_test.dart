import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/utils/crs_utils.dart';

void main() {
  group('CrsUtils.utmToLatLon', () {
    test('converts UTM Zone 51S coordinates to Lat/Lon correctly', () {
      // Known reference: UTM Zone 51S, Easting 700000, Northing 9200000
      // produces approximately Lat -7.23, Lon 124.81 (East Java Sea, Indonesia)
      final result = CrsUtils.utmToLatLon(
        northing: 9_200_000.0,
        easting: 700_000.0,
        crsIdentifier: 'UTM Zone 51S',
      );

      // Allow 0.1 degree tolerance
      expect(result.latitude, closeTo(-7.23, 0.1));
      expect(result.longitude, closeTo(124.81, 0.1));
    });

    test('converts UTM Zone 50S coordinates to Lat/Lon correctly', () {
      // Test a different UTM zone: Zone 50S
      final result = CrsUtils.utmToLatLon(
        northing: 8_500_000.0,
        easting: 500_000.0,
        crsIdentifier: 'UTM Zone 50S',
      );

      // Should be somewhere in the Indian Ocean south of Indonesia
      expect(result.latitude, closeTo(-13.55, 0.1));
      expect(result.longitude, closeTo(117.0, 0.1));
    });

    test('converts UTM Zone 51N coordinates to Lat/Lon correctly', () {
      // Test Northern hemisphere: Zone 51N
      final result = CrsUtils.utmToLatLon(
        northing: 4_500_000.0,
        easting: 300_000.0,
        crsIdentifier: 'UTM Zone 51N',
      );

      // Should be somewhere in the Northern hemisphere (Eurasia)
      expect(result.latitude, closeTo(40.6, 0.1));
      expect(result.longitude, closeTo(120.6, 0.1));
    });

    test('conversion is reversible (round-trip) within Zone 51S', () {
      // Use coordinates within Zone 51S (120°E–126°E, southern hemisphere).
      const originalLat = -7.25;
      const originalLon = 123.0;

      // Convert Lat/Lon to UTM Zone 51S
      final utmResult = CrsUtils.latLonToUtm(
        latitude: originalLat,
        longitude: originalLon,
        crsIdentifier: 'UTM Zone 51S',
      );

      // Convert back to Lat/Lon
      final roundTrip = CrsUtils.utmToLatLon(
        northing: utmResult.northing,
        easting: utmResult.easting,
        crsIdentifier: 'UTM Zone 51S',
      );

      // Round-trip should be accurate to within 0.001 degrees (~1m)
      expect(roundTrip.latitude, closeTo(originalLat, 0.001));
      expect(roundTrip.longitude, closeTo(originalLon, 0.001));
    });

    test('throws ArgumentError for unknown CRS identifier', () {
      expect(
        () => CrsUtils.utmToLatLon(
          northing: 0,
          easting: 0,
          crsIdentifier: 'Unknown CRS',
        ),
        throwsArgumentError,
      );
    });

    test('supports EPSG:32751 (UTM Zone 51S) identifier', () {
      // EPSG:32751 is the official EPSG code for UTM Zone 51S.
      // With EPSG:32751 the longitude wraps to the UTM Zone 51 central meridian
      // which is 123°E.  For northing 9200000, easting 700000 we expect the same
      // result as "UTM Zone 51S" since both use the same definition.
      final result = CrsUtils.utmToLatLon(
        northing: 9_200_000.0,
        easting: 700_000.0,
        crsIdentifier: 'EPSG:32751',
      );

      expect(result.latitude, closeTo(-7.23, 0.1));
      expect(result.longitude, closeTo(124.81, 0.1));
    });
  });

  group('CrsUtils.latLonToUtm', () {
    test('converts Lat/Lon to UTM Zone 51S coordinates correctly', () {
      // Use coordinates within UTM Zone 51S (central meridian 123°E, covers 120°E–126°E).
      // Lat -7.25, Lon 123.0 is approximately on the central meridian of Zone 51S.
      final result = CrsUtils.latLonToUtm(
        latitude: -7.25,
        longitude: 123.0,
        crsIdentifier: 'UTM Zone 51S',
      );

      // On the central meridian, easting should be approximately 500,000m.
      // Allow broad tolerance since the exact value depends on the projection math.
      expect(result.easting, closeTo(500_000, 10_000));
      expect(result.northing, closeTo(9_198_000, 10_000));
    });
  });

  group('LatLonResult', () {
    test('equality works correctly', () {
      const a = LatLonResult(latitude: -7.25, longitude: 112.75);
      const b = LatLonResult(latitude: -7.25, longitude: 112.75);
      const c = LatLonResult(latitude: -8.0, longitude: 113.0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString returns expected format', () {
      const result = LatLonResult(latitude: -7.25, longitude: 112.75);
      expect(
        result.toString(),
        'LatLonResult(latitude: -7.25, longitude: 112.75)',
      );
    });
  });

  group('NorthingEastingResult', () {
    test('equality works correctly', () {
      const a = NorthingEastingResult(northing: 9_200_000, easting: 700_000);
      const b = NorthingEastingResult(northing: 9_200_000, easting: 700_000);
      const c = NorthingEastingResult(northing: 8_500_000, easting: 500_000);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString returns expected format', () {
      const result = NorthingEastingResult(
        northing: 9_200_000,
        easting: 700_000,
      );
      expect(
        result.toString(),
        'NorthingEastingResult(northing: 9200000.0, easting: 700000.0)',
      );
    });
  });
}
