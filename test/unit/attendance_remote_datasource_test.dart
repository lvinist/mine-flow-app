/// Unit tests for [SupabaseAttendanceRemoteDataSource].
///
/// STEP-48.23 re-run (R-2): `attendance_records` carries a non-PK UNIQUE
/// constraint — `unique_user_attendance_per_day UNIQUE (user_id, date)`
/// (`20260718000001_core_schema.sql:88`). A bare `.upsert()` sends no
/// `on_conflict` target, so whenever that user+date already exists on the
/// server (seeded roster, a row from a previous shift, or a conflicting
/// fresh-uuid row), Postgres rejects the write with 23505 and the sync queue
/// item lands in `SyncStatus.failed` — the offline queue can never drain.
/// These tests pin the datasource contract: the upsert MUST target the
/// constraint columns. Fails against the pre-fix bare upsert (onConflict
/// arrives null).
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Awaitable fake for the terminal builder of the query chain — a bare
/// `await builder` must complete successfully.
class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    return Future<List<Map<String, dynamic>>>.value(
      const [],
    ).then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late SupabaseAttendanceRemoteDataSource dataSource;

  const tId = '3f114846-1851-4df8-9a5a-e5ab76577fb2';
  const tUserId = '33333333-3333-3333-3333-333333333333';
  final tDto = AttendanceRecordDto(
    id: tId,
    siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    userId: tUserId,
    date: DateTime(2026, 9, 3),
    status: 'sick',
    remarks: 'Izin sakit shift pagi',
    loggedBy: tUserId,
  );

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    dataSource = SupabaseAttendanceRemoteDataSource(mockClient);
  });

  group('upsertAttendance — STEP-48.23 re-run R-2', () {
    test(
      'targets the non-PK unique constraint (user_id,date), not just the PK',
      () async {
        when(
          () => mockClient.from('attendance_records'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
            ignoreDuplicates: any(named: 'ignoreDuplicates'),
            defaultToNull: any(named: 'defaultToNull'),
          ),
        ).thenAnswer((_) => FakePostgrestFilterBuilder());

        await dataSource.upsertAttendance(tDto);

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

        // The defect: a null on_conflict lets Postgres resolve the conflict on
        // the PK only, so any existing (user_id, date) row rejects the insert
        // with 23505. The fix pins the real constraint.
        expect(
          capturedConflict,
          equals('user_id,date'),
          reason:
              'unique_user_attendance_per_day UNIQUE (user_id, date) must be '
              'the upsert conflict target — a bare upsert 23505s whenever that '
              'user+date already exists and the queue item never drains',
        );

        expect(capturedPayload['id'], equals(tId));
        expect(capturedPayload['user_id'], equals(tUserId));
        // The DTO serializes `date` as a bare calendar date string.
        expect(capturedPayload['date'], equals('2026-09-03'));
        expect(capturedPayload['status'], equals('sick'));
      },
    );

    test(
      'still upserts by the row id so fresh-uuid rows remain addressable',
      () async {
        when(
          () => mockClient.from('attendance_records'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
            ignoreDuplicates: any(named: 'ignoreDuplicates'),
            defaultToNull: any(named: 'defaultToNull'),
          ),
        ).thenAnswer((_) => FakePostgrestFilterBuilder());

        await dataSource.upsertAttendance(tDto);

        // The payload carries the id: with merge-duplicates the conflicted write
        // sets all columns (id included) on the existing row, so server-side
        // read-backs by the freshly generated local uuid still resolve.
        final capturedPayload =
            verify(
                  () => mockQueryBuilder.upsert(
                    captureAny(),
                    onConflict: any(named: 'onConflict'),
                    ignoreDuplicates: any(named: 'ignoreDuplicates'),
                    defaultToNull: any(named: 'defaultToNull'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(capturedPayload['id'], equals(tId));
      },
    );
  });
}
