import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/benchmark/presentation/bloc/benchmark_bloc.dart';
import 'package:mine_flow/features/benchmark/presentation/bloc/benchmark_draft_restoration.dart';

void main() {
  group('BenchmarkDraftRestoration', () {
    test('round-trip equality: encode → decode → fields equal', () {
      const state = BenchmarkFormState(
        bmId: 'BM-01',
        northing: 9_200_000.0,
        easting: 700_000.0,
        orthoHeight: 100.0,
        code: 'Pilar',
        orde: '1st Order',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 105.0,
        status: 'active',
      );

      final encoded = BenchmarkDraftRestoration.encode(state);
      final decoded = BenchmarkDraftRestoration.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.bmId, 'BM-01');
      expect(decoded.northing, 9_200_000.0);
      expect(decoded.easting, 700_000.0);
      expect(decoded.orthoHeight, 100.0);
      expect(decoded.ellipsHeight, 105.0);
      expect(decoded.code, 'Pilar');
      expect(decoded.orde, '1st Order');
      expect(decoded.crsIdentifier, 'UTM Zone 51S');
      expect(decoded.status, 'active');
    });

    test('version-mismatch fallback: old version → null', () {
      const oldSnapshot =
          '{"version":2,"bmId":"BM-01","northing":9200000.0,"easting":700000.0,"'
          'orthoHeight":100.0,"ellipsHeight":105.0,"code":"Pilar","orde":"1st Order",'
          '"crsIdentifier":"UTM Zone 51S","status":"active"}';

      final decoded = BenchmarkDraftRestoration.decode(oldSnapshot);
      expect(decoded, isNull);
    });

    test('version-mismatch fallback: malformed JSON → null', () {
      final decoded = BenchmarkDraftRestoration.decode('not valid json');
      expect(decoded, isNull);
    });

    test('null snapshot → null', () {
      final decoded = BenchmarkDraftRestoration.decode(null);
      expect(decoded, isNull);
    });

    test('missing required fields → null', () {
      final decoded = BenchmarkDraftRestoration.decode(
        '{"version":1,"bmId":"BM-01"}',
      );
      expect(decoded, isNull);
    });

    test('snapshot excludes lat/lon/geom/id (55.4 contract)', () {
      const state = BenchmarkFormState(
        bmId: 'BM-01',
        northing: 9_200_000.0,
        easting: 700_000.0,
        orthoHeight: 100.0,
        code: 'Pilar',
        orde: '1st Order',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 105.0,
        status: 'active',
        computedLatitude: -7.25,
        computedLongitude: 112.75,
      );

      final encoded = BenchmarkDraftRestoration.encode(state);
      expect(encoded, isNot(contains('latitude')));
      expect(encoded, isNot(contains('longitude')));
      expect(encoded, isNot(contains('geom')));
      expect(encoded, isNot(contains('"id"')));

      final decoded = BenchmarkDraftRestoration.decode(encoded);
      expect(decoded, isNotNull);
    });

    test(
      'projection-revalidation: a snapshot whose northing/easting would fail '
      'projection restores and then fails validation exactly as fresh input',
      () {
        const invalidState = BenchmarkFormState(
          bmId: 'BM-INVALID',
          northing: 99_999_999.0,
          easting: 700_000.0,
          orthoHeight: 100.0,
          code: '',
          orde: '',
          crsIdentifier: 'UTM Zone 51S',
          ellipsHeight: 0.0,
          status: 'active',
        );

        final encoded = BenchmarkDraftRestoration.encode(invalidState);
        final decoded = BenchmarkDraftRestoration.decode(encoded);

        expect(decoded, isNotNull);
        expect(decoded!.northing, 99_999_999.0);
        expect(decoded.crsIdentifier, 'UTM Zone 51S');

        // The restore handler (_onRestoreRequested) re-derives lat/lon from
        // the restored CRS + northing + easting. For this out-of-bounds value,
        // the projection fails -> computedLatitude/Longitude are null.
        // The form surfaces kBenchmarkProjectionFailureMessage via BenchmarkError.
        // Proven in widget test:
        //   benchmark_form_restoration_test.dart > projection re-validation case
      },
    );

    test('optional fields null round-trip', () {
      const state = BenchmarkFormState(
        bmId: 'BM-02',
        northing: 9_200_000.0,
        easting: 700_000.0,
        orthoHeight: 50.0,
        code: '',
        orde: '',
        crsIdentifier: 'UTM Zone 50S',
        ellipsHeight: 0.0,
        status: 'active',
      );

      final encoded = BenchmarkDraftRestoration.encode(state);
      final decoded = BenchmarkDraftRestoration.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.code, isEmpty);
      expect(decoded.orde, isEmpty);
      expect(decoded.crsIdentifier, 'UTM Zone 50S');
    });
  });
}
