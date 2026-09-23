import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/features/reporting/domain/entities/date_range_filter.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_request.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_result.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/date_range_selector.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockReportingRepository extends Mock implements ReportingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockReportingRepository reportingRepository;
  late MockZoneRepository zoneRepository;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    await initializeDateFormatting('en_US');
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
    reportingRepository = MockReportingRepository();
    zoneRepository = MockZoneRepository();
    when(() => zoneRepository.getZones()).thenReturn([]);
  });

  Widget wrap(
    Widget child, {
    Locale locale = const Locale('id'),
    double textScaleFactor = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
      child: FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets(
    'showAppContextualReportDialog opens dialog and keeps origin mounted',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppContextualReportDialog(
                    context: context,
                    reportType: ReportType.attendance,
                    sourceTitle: 'Kehadiran',
                    reportingRepository: reportingRepository,
                    zoneRepository: zoneRepository,
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Laporan: Kehadiran'), findsOneWidget);
      expect(
        find.text('Laporan Kehadiran'),
        findsWidgets,
      ); // reportType.displayName
      expect(
        find.text('Buka Dialog'),
        findsOneWidget,
      ); // Origin route still mounted
    },
  );

  testWidgets(
    'context prefill: pre-fills initial date range and zone into dialog',
    (tester) async {
      when(() => zoneRepository.getZones()).thenReturn([
        const ZoneEntity(id: 'zone-1', siteId: 'site-1', name: 'Pit Utara'),
        const ZoneEntity(id: 'zone-2', siteId: 'site-1', name: 'Pit Selatan'),
      ]);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppContextualReportDialog(
                    context: context,
                    reportType: ReportType.cutFill,
                    sourceTitle: 'Cut & Fill',
                    initialDateRange: DateTimeRange(
                      start: DateTime(2026, 9, 1),
                      end: DateTime(2026, 9, 10),
                    ),
                    initialZoneId: 'zone-1',
                    reportingRepository: reportingRepository,
                    zoneRepository: zoneRepository,
                  );
                },
                child: const Text('Buka Cut & Fill'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Cut & Fill'));
      await tester.pumpAndSettle();

      expect(find.byType(DateRangeSelector), findsOneWidget);
      expect(find.text('Pit Utara'), findsOneWidget);
    },
  );

  testWidgets(
    'unsupported-filters-preserved-but-not-shown: origin snapshot is preserved and not shown as form fields',
    (tester) async {
      final snapshot = {
        'searchQuery': 'pit-excavator-01',
        'statusFilter': 'pending_approval',
        'shift': 'night_shift',
      };

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppContextualReportDialog(
                    context: context,
                    reportType: ReportType.cutFill,
                    sourceTitle: 'Cut & Fill',
                    originFiltersSnapshot: snapshot,
                    reportingRepository: reportingRepository,
                    zoneRepository: zoneRepository,
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<AppContextualReportDialog>(
        find.byType(AppContextualReportDialog),
      );
      expect(dialog.originFiltersSnapshot['searchQuery'], 'pit-excavator-01');
      expect(dialog.originFiltersSnapshot['statusFilter'], 'pending_approval');
      expect(dialog.originFiltersSnapshot['shift'], 'night_shift');

      // Unsupported list filters must not be falsely displayed as report controls
      expect(find.text('pit-excavator-01'), findsNothing);
      expect(find.text('pending_approval'), findsNothing);
      expect(find.text('night_shift'), findsNothing);
    },
  );

  testWidgets(
    'loading duplicate prevention: disables submit and prevents duplicate generation while busy',
    (tester) async {
      final completer = Completer<ReportResult>();
      when(
        () => reportingRepository.generateReport(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppContextualReportDialog(
                    context: context,
                    reportType: ReportType.attendance,
                    sourceTitle: 'Kehadiran',
                    reportingRepository: reportingRepository,
                    zoneRepository: zoneRepository,
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      final generateButton = find.byKey(const Key('generate_report_button'));
      expect(generateButton, findsOneWidget);

      // Trigger first generation
      await tester.tap(generateButton);
      await tester.pump();

      // In loading state: FCircularProgress is shown
      expect(find.byType(FCircularProgress), findsOneWidget);

      // Attempt duplicate tap while loading
      await tester.tap(generateButton, warnIfMissed: false);
      await tester.pump();

      // Complete async report generation
      completer.complete(
        ReportResult(
          request: ReportRequest(
            id: 'r-1',
            reportType: ReportType.attendance,
            siteId: 'site-1',
            dateRange: DateRangeFilter.currentWeek(),
            createdAt: DateTime(2026, 9, 1),
          ),
          pdfBytes: Uint8List.fromList([1, 2, 3]),
          title: 'Laporan Kehadiran',
          recordCount: 5,
          generatedAt: DateTime(2026, 9, 1),
        ),
      );
      await tester.pumpAndSettle();

      // Repository must have been called only once despite duplicate taps
      verify(() => reportingRepository.generateReport(any())).called(1);
    },
  );

  testWidgets(
    'error/retry with config intact: preserves selected parameters on failure and allows retry',
    (tester) async {
      when(
        () => reportingRepository.generateReport(any()),
      ).thenThrow(Exception('Simulated server connection failure'));

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppContextualReportDialog(
                    context: context,
                    reportType: ReportType.cutFill,
                    sourceTitle: 'Cut & Fill',
                    reportingRepository: reportingRepository,
                    zoneRepository: zoneRepository,
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      final generateButton = find.byKey(const Key('generate_report_button'));
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Error message is displayed
      expect(
        find.textContaining('Simulated server connection failure'),
        findsOneWidget,
      );

      // Configuration controls remain intact
      expect(find.byType(DateRangeSelector), findsOneWidget);

      // Now prepare mock for retry success
      when(() => reportingRepository.generateReport(any())).thenAnswer(
        (inv) async => ReportResult(
          request: inv.positionalArguments.first as ReportRequest,
          pdfBytes: Uint8List.fromList([1, 2]),
          title: 'Laporan Cut & Fill Final',
          recordCount: 12,
          generatedAt: DateTime(2026, 9, 1),
        ),
      );

      // Retry generation
      await tester.ensureVisible(generateButton);
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Success view appears with summary and Tutup button
      expect(find.text('Laporan Cut & Fill Final'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);
    },
  );

  testWidgets(
    'focus trap and focus return: contains FocusTraversalGroup and returns focus upon dismiss',
    (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                focusNode: focusNode,
                onPressed: () {
                  showAppContextualReportDialog(
                    context: context,
                    reportType: ReportType.attendance,
                    sourceTitle: 'Kehadiran',
                    reportingRepository: reportingRepository,
                    zoneRepository: zoneRepository,
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      // FocusTraversalGroup is present inside dialog
      expect(
        find.descendant(
          of: find.byType(AppContextualReportDialog),
          matching: find.byType(FocusTraversalGroup),
        ),
        findsOneWidget,
      );

      // Dismiss dialog via close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog is popped
      expect(find.byType(AppContextualReportDialog), findsNothing);
      // Focus returns to invoking control
      expect(focusNode.hasFocus, isTrue);
    },
  );

  testWidgets(
    'Escape/back/barrier: barrier tap dismisses when clean and is blocked when busy',
    (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppContextualReportDialog(
                    context: context,
                    reportType: ReportType.attendance,
                    sourceTitle: 'Kehadiran',
                    reportingRepository: reportingRepository,
                    zoneRepository: zoneRepository,
                    onComplete: () => completed = true,
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      // Tap outside dialog to trigger barrier dismissal
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AppContextualReportDialog), findsNothing);
      expect(completed, isTrue);

      // Now test barrier blocked when busy
      final completer = Completer<ReportResult>();
      when(
        () => reportingRepository.generateReport(any()),
      ).thenAnswer((_) => completer.future);

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();

      // Start loading
      await tester.tap(find.byKey(const Key('generate_report_button')));
      await tester.pump();

      // Tap barrier while busy
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      // Dialog must remain open while busy
      expect(find.byType(AppContextualReportDialog), findsOneWidget);

      completer.complete(
        ReportResult(
          request: ReportRequest(
            id: 'r-2',
            reportType: ReportType.attendance,
            siteId: 'site-1',
            dateRange: DateRangeFilter.currentWeek(),
            createdAt: DateTime(2026, 9, 1),
          ),
          pdfBytes: Uint8List.fromList([1]),
          title: 'Done',
          recordCount: 1,
          generatedAt: DateTime(2026, 9, 1),
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'localization and text scale: renders cleanly across locales and enlarged text scale',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      // Test English localization
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppContextualReportDialog(
                    context: context,
                    reportType: ReportType.attendance,
                    sourceTitle: 'Attendance',
                    reportingRepository: reportingRepository,
                    zoneRepository: zoneRepository,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
          locale: const Locale('en'),
          textScaleFactor: 1.8,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Report: Attendance'), findsOneWidget);
      expect(find.text('Generate Report'), findsOneWidget);
      expect(errors, isEmpty);
    },
  );
}
