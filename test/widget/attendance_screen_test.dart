import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mine_flow/core/init/app_initializer.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/crew_roster_item.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mine_flow/main.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

class MockReportingRepository extends Mock implements ReportingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

class FakeAppServices extends Fake implements AppServices {
  @override
  final ReportingRepository reportingRepository;
  @override
  final ZoneRepository zoneRepository;

  FakeAppServices({
    required this.reportingRepository,
    required this.zoneRepository,
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(<AttendanceRecord>[]);
    registerFallbackValue(ReportType.attendance);
    registerFallbackValue(
      DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );
  });

  late MockAttendanceRepository mockRepository;
  late MockReportingRepository mockReportingRepository;
  late MockZoneRepository mockZoneRepository;

  final tDate = DateTime(2026, 7, 18);
  const tSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  final tRecords = [
    AttendanceRecord(
      id: 'att-001',
      siteId: tSiteId,
      userId: 'KRU-001',
      date: tDate,
      status: AttendanceStatus.present,
      loggedBy: 'Foreman Alpha',
    ),
    AttendanceRecord(
      id: 'att-002',
      siteId: tSiteId,
      userId: 'KRU-002',
      date: tDate,
      status: AttendanceStatus.absent,
      remarks: 'Demam',
      loggedBy: 'Foreman Alpha',
    ),
  ];

  setUp(() {
    mockRepository = MockAttendanceRepository();
    mockReportingRepository = MockReportingRepository();
    mockZoneRepository = MockZoneRepository();

    when(() => mockZoneRepository.getZones()).thenReturn([]);
    when(
      () => mockRepository.getAttendanceForDate(
        any(),
        siteId: any(named: 'siteId'),
      ),
    ).thenAnswer((_) async => tRecords);
    when(
      () => mockRepository.saveAttendanceBatch(any()),
    ).thenAnswer((_) async => {});

    appServices = FakeAppServices(
      reportingRepository: mockReportingRepository,
      zoneRepository: mockZoneRepository,
    );
  });

  tearDown(() {
    appServices = null;
  });

  Widget buildTestWidget({
    GoRouter? router,
    FThemeData? theme,
    Locale locale = const Locale('id'),
    AttendanceRepository? repository,
  }) {
    final effectiveRepo = repository ?? mockRepository;
    final effectiveRouter =
        router ??
        GoRouter(
          initialLocation: '/teams/attendance',
          routes: [
            GoRoute(
              path: '/teams/attendance',
              builder: (context, state) => AttendanceScreen(
                repository: effectiveRepo,
                initialSiteId: tSiteId,
                initialDate: tDate,
              ),
            ),
            GoRoute(
              path: '/teams/attendance/form',
              name: 'attendance-form',
              builder: (context, state) =>
                  const Scaffold(body: Text('ATTENDANCE_FORM_SHEET')),
            ),
          ],
        );

    return FTheme(
      data: theme ?? FTheme.neutral.light.touch,
      child: MaterialApp.router(
        routerConfig: effectiveRouter,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FToaster(child: child!),
      ),
    );
  }

  group('AttendanceScreen Widget Tests', () {
    testWidgets(
      'should render app bar, summary card, search field, and crew roster',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Absensi Kru Lapangan'), findsOneWidget);
        expect(find.byType(AttendanceSummaryCard), findsOneWidget);
        expect(find.text('Ringkasan Kehadiran'), findsOneWidget);
        expect(find.text('Cari nama kru atau catatan...'), findsOneWidget);

        expect(find.byType(CrewRosterItem), findsNWidgets(2));
        // STEP-55.5 (spec §4.4 item 3): cards lead with the real name and
        // never expose the crew UUID. The fixture records carry no userName,
        // so the fallback label is the generic 'Kru'.
        expect(find.text('Kru'), findsNWidgets(2));
        expect(find.textContaining('KRU-001'), findsNothing);
      },
    );

    testWidgets('should filter crew roster when typing in search text field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CrewRosterItem), findsNWidgets(2));

      // Search by crew id — the list's search still matches the id as well
      // as the name and remarks (STEP-55.5 attendance_state.filteredRecords).
      await tester.enterText(find.byType(TextField), 'KRU-001');
      await tester.pumpAndSettle();

      expect(find.byType(CrewRosterItem), findsOneWidget);
      expect(find.text('Kru'), findsOneWidget);
    });

    testWidgets('should navigate dates when pressing next date arrow', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final forwardArrow = find.byIcon(LucideIcons.arrowRight);
      expect(forwardArrow, findsOneWidget);

      await tester.tap(forwardArrow);
      await tester.pumpAndSettle();

      final expectedNextDate = tDate.add(const Duration(days: 1));
      verify(
        () => mockRepository.getAttendanceForDate(
          expectedNextDate,
          siteId: tSiteId,
        ),
      ).called(1);
    });
  });

  group(
    'AttendanceScreen Action Buttons & Material FAB Purge (spec §4.4 item 9, FC-54.5-011)',
    () {
      testWidgets(
        'renders ForUI FButton actions in positioned overlay and ZERO FloatingActionButton',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          // Purge assertion: Zero Material FloatingActionButton on screen
          expect(
            find.byType(FloatingActionButton),
            findsNothing,
            reason:
                'No Material FloatingActionButton permitted in attendance feature',
          );

          // ForUI FButton report button in positioned overlay
          final reportBtnFinder = find.byKey(
            const Key('report_attendance_btn'),
          );
          expect(reportBtnFinder, findsOneWidget);
          expect(
            find.bySemanticsLabel('Buat Laporan Kehadiran'),
            findsOneWidget,
          );

          // ForUI FButton add/input button in positioned overlay
          final addBtnFinder = find.byKey(const Key('add_attendance_btn'));
          expect(addBtnFinder, findsOneWidget);

          // 48dp minimum touch target height assertions
          final reportSizedBox = tester.widget<SizedBox>(
            find
                .ancestor(of: reportBtnFinder, matching: find.byType(SizedBox))
                .first,
          );
          expect(reportSizedBox.height, 48);

          final addSizedBox = tester.widget<SizedBox>(
            find
                .ancestor(of: addBtnFinder, matching: find.byType(SizedBox))
                .first,
          );
          expect(addSizedBox.height, 48);
        },
      );

      testWidgets(
        'action buttons are disabled when attendance state is not loaded',
        (tester) async {
          final completer = Completer<List<AttendanceRecord>>();
          when(
            () => mockRepository.getAttendanceForDate(
              any(),
              siteId: any(named: 'siteId'),
            ),
          ).thenAnswer((_) => completer.future);

          await tester.pumpWidget(buildTestWidget());
          // Pump one frame without settling so state remains loading
          await tester.pump();

          final reportBtn = tester.widget<FButton>(
            find.byKey(const Key('report_attendance_btn')),
          );
          final addBtn = tester.widget<FButton>(
            find.byKey(const Key('add_attendance_btn')),
          );

          expect(
            reportBtn.onPress,
            isNull,
            reason:
                'Report button must be disabled while attendance is loading',
          );
          expect(
            addBtn.onPress,
            isNull,
            reason: 'Input button must be disabled while attendance is loading',
          );

          completer.complete(tRecords);
          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'tapping report button opens AppContextualReportDialog seeded with selected date',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          final reportBtnFinder = find.byKey(
            const Key('report_attendance_btn'),
          );
          await tester.tap(reportBtnFinder);
          await tester.pumpAndSettle();

          expect(find.byType(AppContextualReportDialog), findsOneWidget);
          expect(find.text('Laporan: Absensi Kru'), findsOneWidget);
        },
      );

      testWidgets(
        'tapping Input Absensi button navigates to form sheet route preserving list beneath',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          final addBtnFinder = find.byKey(const Key('add_attendance_btn'));
          await tester.tap(addBtnFinder);
          await tester.pumpAndSettle();

          expect(find.text('ATTENDANCE_FORM_SHEET'), findsOneWidget);
        },
      );
    },
  );

  group(
    'AttendanceScreen Mechanical Coverage (FC-54.5-004..013, runtime audit)',
    () {
      testWidgets('tapping calendar button opens date picker dialog', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final calendarPicker = find.byIcon(LucideIcons.calendarDays);
        expect(calendarPicker, findsOneWidget);

        await tester.tap(calendarPicker);
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);
      });

      testWidgets(
        'tapping status filter opens popover and filters crew roster',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          final filterBtn = find.byIcon(LucideIcons.filter);
          expect(filterBtn, findsOneWidget);

          await tester.tap(filterBtn);
          await tester.pumpAndSettle();

          final popover = find.byType(AppFilterPopover);
          expect(popover, findsOneWidget);

          // Select 'Masuk' option in popover
          final masukOption = find.descendant(
            of: popover,
            matching: find.text('Masuk'),
          );
          await tester.tap(masukOption);
          await tester.pumpAndSettle();

          // Apply filter
          final applyButton = find.descendant(
            of: popover,
            matching: find.text('Terapkan'),
          );
          await tester.tap(applyButton);
          await tester.pumpAndSettle();

          expect(find.byType(AppFilterPopover), findsNothing);
          expect(find.text('Filter: Masuk'), findsOneWidget);
          // Only present crew member shown
          expect(find.byType(CrewRosterItem), findsOneWidget);
        },
      );

      testWidgets(
        'mechanical accessibility: 2.0x text scale renders without overflow',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          tester.platformDispatcher.textScaleFactorTestValue = 2.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Absensi Kru Lapangan'), findsOneWidget);
        },
      );

      testWidgets(
        'mechanical theme: dark mode renders cleanly without errors',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1200);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildTestWidget(theme: FTheme.neutral.dark.touch),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Absensi Kru Lapangan'), findsOneWidget);
        },
      );
    },
  );
}
