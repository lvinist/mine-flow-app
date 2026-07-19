import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/error/failures.dart';
import 'package:mine_flow/features/reporting/domain/entities/date_range_filter.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_request.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_result.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_state.dart';

class MockReportingRepository extends Mock implements ReportingRepository {}

class FakeReportRequest extends Fake implements ReportRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeReportRequest());
  });
  const defaultSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  late MockReportingRepository mockRepository;
  late ReportCubit reportCubit;

  setUp(() {
    mockRepository = MockReportingRepository();
    reportCubit = ReportCubit(repository: mockRepository);
  });

  tearDown(() {
    reportCubit.close();
  });

  group('selectReportType', () {
    blocTest<ReportCubit, ReportState>(
      'emits [ReportInitial] when selecting a report type',
      build: () => reportCubit,
      act: (cubit) => cubit.selectReportType(ReportType.attendance),
      expect: () => [const ReportInitial()],
    );
  });

  group('setDateRange', () {
    blocTest<ReportCubit, ReportState>(
      'emits [ReportInitial] when date range changes',
      build: () => reportCubit,
      act: (cubit) => cubit.setDateRange(
        DateRangeFilter(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ),
      expect: () => [const ReportInitial()],
    );

    blocTest<ReportCubit, ReportState>(
      'does not emit when date range changes during loading',
      build: () => reportCubit,
      seed: () => const ReportLoading(),
      act: (cubit) => cubit.setDateRange(
        DateRangeFilter(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ),
      expect: () => [],
    );
  });

  group('generateReport', () {
    final tResult = ReportResult(
      request: ReportRequest(
        id: 'req-001',
        reportType: ReportType.attendance,
        siteId: defaultSiteId,
        dateRange: DateRangeFilter(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
        createdAt: DateTime(2026, 7, 18),
      ),
      pdfBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      title: 'Laporan Kehadiran',
      recordCount: 10,
      generatedAt: DateTime(2026, 7, 18),
    );

    blocTest<ReportCubit, ReportState>(
      'emits [ReportLoading, ReportSuccess] when generation succeeds',
      build: () {
        when(
          () => mockRepository.generateReport(any()),
        ).thenAnswer((_) async => tResult);
        return reportCubit;
      },
      act: (cubit) {
        cubit.selectReportType(ReportType.attendance);
        cubit.generateReport(siteId: defaultSiteId);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const ReportInitial(),
        const ReportLoading(),
        isA<ReportSuccess>().having(
          (s) => s.result.title,
          'title matches',
          equals('Laporan Kehadiran'),
        ),
      ],
    );

    blocTest<ReportCubit, ReportState>(
      'emits [ReportLoading, ReportError] when repository throws ServerFailure',
      build: () {
        when(
          () => mockRepository.generateReport(any()),
        ).thenThrow(const ServerFailure('Database error'));
        return reportCubit;
      },
      act: (cubit) {
        cubit.selectReportType(ReportType.cutFill);
        cubit.generateReport(siteId: defaultSiteId);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const ReportInitial(),
        const ReportLoading(),
        const ReportError('Database error'),
      ],
    );

    blocTest<ReportCubit, ReportState>(
      'emits [ReportError] when no report type is selected',
      build: () => reportCubit,
      act: (cubit) => cubit.generateReport(siteId: defaultSiteId),
      expect: () => [const ReportError('Pilih jenis laporan terlebih dahulu.')],
    );
  });

  group('resetReport', () {
    blocTest<ReportCubit, ReportState>(
      'emits [ReportInitial] when reset is called',
      build: () => reportCubit,
      seed: () => const ReportLoading(),
      act: (cubit) => cubit.resetReport(),
      expect: () => [const ReportInitial()],
    );
  });
}
