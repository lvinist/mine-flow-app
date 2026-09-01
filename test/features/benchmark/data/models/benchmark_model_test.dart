import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';

void main() {
  group('BenchmarkModel', () {
    const testId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    const testBmId = 'BM-001';
    const testNorthing = 9_200_000.0;
    const testEasting = 700_000.0;
    const testOrthoHeight = 100.5;
    const testCode = 'Pilar';
    const testOrde = '1st Order';
    const testLatitude = -7.25;
    const testLongitude = 112.75;
    const testEllipsHeight = 105.2;
    const testStatus = 'active';

    final testJson = <String, dynamic>{
      'id': testId,
      'bm_id': testBmId,
      'northing': testNorthing,
      'easting': testEasting,
      'ortho_height': testOrthoHeight,
      'code': testCode,
      'orde': testOrde,
      'geom': 'POINT(112.75 -7.25)',
      'latitude': testLatitude,
      'longitude': testLongitude,
      'ellips_height': testEllipsHeight,
      'status': testStatus,
    };

    group('fromJson', () {
      test('deserializes from Supabase JSON correctly', () {
        final model = BenchmarkModel.fromJson(testJson);

        expect(model.id, testId);
        expect(model.bmId, testBmId);
        expect(model.northing, testNorthing);
        expect(model.easting, testEasting);
        expect(model.orthoHeight, testOrthoHeight);
        expect(model.code, testCode);
        expect(model.orde, testOrde);
        expect(model.geom, 'POINT(112.75 -7.25)');
        expect(model.latitude, testLatitude);
        expect(model.longitude, testLongitude);
        expect(model.ellipsHeight, testEllipsHeight);
        expect(model.status, testStatus);
      });

      test('handles null geom field gracefully', () {
        final jsonNoGeom = Map<String, dynamic>.from(testJson)..remove('geom');
        final model = BenchmarkModel.fromJson(jsonNoGeom);

        expect(model.geom, isNull);
      });
    });

    group('toJson', () {
      test('serializes to Supabase JSON correctly', () {
        final model = BenchmarkModel.fromJson(testJson);
        final json = model.toJson();

        expect(json['id'], testId);
        expect(json['bm_id'], testBmId);
        expect(json['northing'], testNorthing);
        expect(json['easting'], testEasting);
        expect(json['ortho_height'], testOrthoHeight);
        expect(json['code'], testCode);
        expect(json['orde'], testOrde);
        expect(json['geom'], 'POINT(112.75 -7.25)');
        expect(json['latitude'], testLatitude);
        expect(json['longitude'], testLongitude);
        expect(json['ellips_height'], testEllipsHeight);
        expect(json['status'], testStatus);
      });

      test('omits geom when null', () {
        final model = BenchmarkModel.fromJson(
          Map<String, dynamic>.from(testJson)..remove('geom'),
        );
        final json = model.toJson();

        expect(json.containsKey('geom'), isFalse);
      });
    });

    group('Hive serialization', () {
      test('toHiveJson uses camelCase keys', () {
        final model = BenchmarkModel.fromJson(testJson);
        final hiveJson = model.toHiveJson();

        expect(hiveJson['id'], testId);
        expect(hiveJson['bmId'], testBmId);
        expect(hiveJson['northing'], testNorthing);
        expect(hiveJson['easting'], testEasting);
        expect(hiveJson['orthoHeight'], testOrthoHeight);
        expect(hiveJson['code'], testCode);
        expect(hiveJson['orde'], testOrde);
        expect(hiveJson['geom'], 'POINT(112.75 -7.25)');
        expect(hiveJson['latitude'], testLatitude);
        expect(hiveJson['longitude'], testLongitude);
        expect(hiveJson['ellipsHeight'], testEllipsHeight);
        expect(hiveJson['status'], testStatus);
      });

      test('fromHiveJson deserializes camelCase JSON correctly', () {
        final model = BenchmarkModel.fromJson(testJson);
        final hiveJson = model.toHiveJson();
        final restored = BenchmarkModel.fromHiveJson(hiveJson);

        expect(restored.id, model.id);
        expect(restored.bmId, model.bmId);
        expect(restored.northing, model.northing);
        expect(restored.easting, model.easting);
        expect(restored.orthoHeight, model.orthoHeight);
        expect(restored.code, model.code);
        expect(restored.orde, model.orde);
        expect(restored.geom, model.geom);
        expect(restored.latitude, model.latitude);
        expect(restored.longitude, model.longitude);
        expect(restored.ellipsHeight, model.ellipsHeight);
        expect(restored.status, model.status);
      });
    });

    group('Domain conversion', () {
      test('toDomain creates correct Benchmark entity', () {
        final model = BenchmarkModel.fromJson(testJson);
        final entity = model.toDomain();

        expect(entity.id, testId);
        expect(entity.bmId, testBmId);
        expect(entity.northing, testNorthing);
        expect(entity.easting, testEasting);
        expect(entity.orthoHeight, testOrthoHeight);
        expect(entity.code, testCode);
        expect(entity.orde, testOrde);
        expect(entity.geom, 'POINT(112.75 -7.25)');
        expect(entity.latitude, testLatitude);
        expect(entity.longitude, testLongitude);
        expect(entity.ellipsHeight, testEllipsHeight);
        expect(entity.status, testStatus);
      });

      test('fromDomain creates correct model from entity', () {
        const entity = Benchmark(
          id: testId,
          bmId: testBmId,
          northing: testNorthing,
          easting: testEasting,
          orthoHeight: testOrthoHeight,
          code: testCode,
          orde: testOrde,
          geom: 'POINT(112.75 -7.25)',
          latitude: testLatitude,
          longitude: testLongitude,
          ellipsHeight: testEllipsHeight,
          status: testStatus,
        );
        final model = BenchmarkModel.fromDomain(entity);

        expect(model.id, entity.id);
        expect(model.bmId, entity.bmId);
        expect(model.northing, entity.northing);
        expect(model.easting, entity.easting);
        expect(model.orthoHeight, entity.orthoHeight);
        expect(model.code, entity.code);
        expect(model.orde, entity.orde);
        expect(model.geom, entity.geom);
        expect(model.latitude, entity.latitude);
        expect(model.longitude, entity.longitude);
        expect(model.ellipsHeight, entity.ellipsHeight);
        expect(model.status, entity.status);
      });

      test('model <-> domain round-trip preserves all fields', () {
        final model = BenchmarkModel.fromJson(testJson);
        final entity = model.toDomain();
        final roundTrip = BenchmarkModel.fromDomain(entity);

        expect(roundTrip.id, model.id);
        expect(roundTrip.bmId, model.bmId);
        expect(roundTrip.northing, model.northing);
        expect(roundTrip.easting, model.easting);
        expect(roundTrip.orthoHeight, model.orthoHeight);
        expect(roundTrip.code, model.code);
        expect(roundTrip.orde, model.orde);
        expect(roundTrip.geom, model.geom);
        expect(roundTrip.latitude, model.latitude);
        expect(roundTrip.longitude, model.longitude);
        expect(roundTrip.ellipsHeight, model.ellipsHeight);
        expect(roundTrip.status, model.status);
      });
    });
  });
}
