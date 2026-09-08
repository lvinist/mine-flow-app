// Regression coverage for STEP-48.26 residual failure R-1 (findings register
// BH-019): `ReportConfigPage` is rooted in a ForUI `FScaffold`, so nothing in
// its subtree has a Material ancestor. A Material-only form control placed here
// throws "No Material widget found" at runtime and killed the reporting journey
// on both platforms in CI run 33480009094.
//
// These tests render the real page inside the app's real root shape
// (MaterialApp + FTheme, no enclosing Scaffold) and fail on any Flutter error,
// which is the surface the E2E journey exercises.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/features/reporting/domain/entities/date_range_filter.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_request.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_result.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/pages/report_config_page.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/date_range_selector.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockReportingRepository extends Mock implements ReportingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockReportingRepository repository;
  late MockZoneRepository zoneRepository;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    registerFallbackValue(
      ReportRequest(
        id: 'fallback',
        reportType: ReportType.attendance,
        siteId: 'site-1',
        dateRange: DateRangeFilter.currentWeek(),
        createdAt: DateTime(2026, 9),
      ),
    );
  });

  setUp(() {
    repository = MockReportingRepository();
    zoneRepository = MockZoneRepository();
    when(() => zoneRepository.getZones()).thenReturn([]);
  });

  /// Renders the real page inside the app's real root shape: `/reports/config`
  /// sits OUTSIDE the shell's `StatefulShellRoute`, so there is no
  /// `Scaffold`/`Material` above the page. `ZoneCubit` is provided because the
  /// route provides it and the cut/fill form uses a `ZonePicker`.
  Widget wrap(Widget child) => FTheme(
    data: FTheme.neutral.light.touch,
    child: MaterialApp(
      locale: const Locale('id'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ReportCubit>(
            create: (_) => ReportCubit(repository: repository),
          ),
          BlocProvider<ZoneCubit>(
            create: (_) => ZoneCubit(repository: zoneRepository)..loadZones(),
          ),
        ],
        child: child,
      ),
    ),
  );

  testWidgets(
    'renders without a Material ancestor for every report type (R-1/BH-019)',
    (tester) async {
      for (final type in ReportType.values) {
        final errors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = errors.add;

        await tester.pumpWidget(wrap(ReportConfigPage(reportType: type)));
        await tester.pumpAndSettle();

        FlutterError.onError = previousOnError;

        expect(
          errors.map((e) => e.exceptionAsString()),
          isEmpty,
          reason:
              'ReportConfigPage(${type.name}) must build under FScaffold with '
              'no Material ancestor — a Material-only control here is BH-019',
        );
        expect(find.byType(DateRangeSelector), findsOneWidget);
      }
    },
  );

  testWidgets('date-range options are selectable without a Material ancestor', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      wrap(const ReportConfigPage(reportType: ReportType.cutFill)),
    );
    await tester.pumpAndSettle();

    // Open the selector and pick a different preset. Opening the overlay is the
    // step that previously threw, because the Material dropdown menu route
    // asserted a Material ancestor.
    await tester.tap(find.text('Minggu Ini'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bulan Ini').last);
    await tester.pumpAndSettle();

    expect(errors.map((e) => e.exceptionAsString()), isEmpty);
    expect(find.text('Bulan Ini'), findsWidgets);

    final cubit = tester
        .element(find.byType(ReportConfigPage))
        .read<ReportCubit>();
    expect(
      cubit.currentRange.startDate.day,
      1,
      reason: 'selecting "Bulan Ini" must push the month range into the cubit',
    );
  });

  testWidgets('the zone picker opens without a Material ancestor (R-1)', (
    tester,
  ) async {
    // The cut/fill report config embeds a ZonePicker, whose CreatableCombobox
    // option tiles used a Material InkWell. Opening it inside FScaffold threw
    // the same "No Material widget found" as BH-019 — the defect class, not just
    // the one line the failure log named.
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;

    await tester.pumpWidget(
      wrap(const ReportConfigPage(reportType: ReportType.cutFill)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Pilih Zona Operasional...'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    FlutterError.onError = previousOnError;

    expect(
      errors.map((e) => e.exceptionAsString()),
      isEmpty,
      reason: 'opening the zone combobox must not require a Material ancestor',
    );
  });

  testWidgets('selector is disabled while a report is generating (NR-001)', (
    tester,
  ) async {
    when(() => repository.generateReport(any())).thenAnswer((invocation) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return ReportResult(
        request: invocation.positionalArguments.first as ReportRequest,
        pdfBytes: Uint8List.fromList(const [1, 2, 3]),
        title: 'Laporan Cut/Fill',
        recordCount: 1,
        generatedAt: DateTime(2026, 9, 1),
      );
    });

    await tester.pumpWidget(
      wrap(const ReportConfigPage(reportType: ReportType.cutFill)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FButton, 'Buat Laporan'));
    await tester.pump();

    final selector = tester.widget<DateRangeSelector>(
      find.byType(DateRangeSelector),
    );
    expect(selector.enabled, isFalse);

    await tester.pumpAndSettle();
  });
}
