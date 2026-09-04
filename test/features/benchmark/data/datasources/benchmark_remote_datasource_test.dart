/// Unit tests for [BenchmarkRemoteDataSourceImpl].
///
/// STEP-48.23 re-run (R-2 sibling sweep): `benchmarks` carries a non-PK UNIQUE
/// constraint — `benchmarks_site_bm_id_key UNIQUE (site_id, bm_id)`
/// (`20260831000002_step_48_17_benchmarks.sql:22`). A bare `.upsert()` sends no
/// `on_conflict` target, so re-saving a benchmark whose (site, bm_id) already
/// exists on the server is rejected with 23505 (`duplicate key value violates
/// unique constraint "benchmarks_site_bm_id_key"` — observed live in the
/// STEP-48.24 Android run-8 log), and the queue item lands in
/// `SyncStatus.failed`. This test pins the datasource contract: the upsert MUST
/// target the constraint columns. Fails against the pre-fix bare upsert.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/benchmark/data/datasources/benchmark_remote_datasource.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

/// Awaitable fake for the terminal `.single()` builder.
class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  FakePostgrestTransformBuilder(this._data);
  final Map<String, dynamic> _data;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic> value) onValue, {
    Function? onError,
  }) {
    return Future<Map<String, dynamic>>.value(
      _data,
    ).then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late BenchmarkRemoteDataSourceImpl dataSource;

  const testId = 'f7415018-5b35-445e-88da-ba97e9d206c2';
  const testModel = BenchmarkModel(
    id: testId,
    bmId: 'BM-R2-001',
    northing: 9_200_000.0,
    easting: 700_000.0,
    orthoHeight: 100.5,
    code: 'Pilar',
    orde: '1st Order',
    geom: null,
    latitude: -7.25,
    longitude: 112.75,
    ellipsHeight: 105.2,
    status: 'active',
  );

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    dataSource = BenchmarkRemoteDataSourceImpl(supabaseClient: mockClient);
  });

  group('saveBenchmark — STEP-48.23 re-run R-2 sibling', () {
    test(
      'targets the non-PK unique constraint (site_id,bm_id), not just the PK',
      () async {
        when(
          () => mockClient.from('benchmarks'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
            ignoreDuplicates: any(named: 'ignoreDuplicates'),
            defaultToNull: any(named: 'defaultToNull'),
          ),
        ).thenAnswer((_) => mockFilterBuilder);
        when(
          () => mockFilterBuilder.select(),
        ).thenAnswer((_) => mockFilterBuilder);
        when(
          () => mockFilterBuilder.single(),
        ).thenAnswer((_) => FakePostgrestTransformBuilder(testModel.toJson()));

        await dataSource.saveBenchmark(testModel);

        // Captures are collected in evaluation order: positional payload
        // first, then the named onConflict argument.
        final captures = verify(
          () => mockQueryBuilder.upsert(
            captureAny(),
            onConflict: captureAny(named: 'onConflict'),
            ignoreDuplicates: any(named: 'ignoreDuplicates'),
            defaultToNull: any(named: 'defaultToNull'),
          ),
        ).captured;
        final capturedPayload = captures[0] as Map<String, dynamic>;
        final capturedConflict = captures[1] as String?;

        expect(
          capturedConflict,
          equals('site_id,bm_id'),
          reason:
              'benchmarks_site_bm_id_key UNIQUE (site_id, bm_id) must be the '
              'upsert conflict target — a bare upsert 23505s on re-save of an '
              'existing (site, bm_id) and the queue item never drains',
        );

        expect(capturedPayload['id'], equals(testId));
        expect(capturedPayload['bm_id'], equals('BM-R2-001'));
        // site_id must always be emitted — the conflict target needs it.
        expect(
          capturedPayload['site_id'],
          equals('f47ac10b-58cc-4372-a567-0e02b2c3d479'),
        );
      },
    );
  });
}
