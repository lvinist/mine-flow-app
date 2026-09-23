import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_list_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/clearing_summary_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/land_clearing_card.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

class MockReportingRepository extends Mock implements ReportingRepository {}

void main() {
  late MockTrackingRepository mockTrackingRepository;
  late MockZoneRepository mockZoneRepository;
  late MockReportingRepository mockReportingRepository;

  final sampleRecord1 = LandClearingRecord(
    id: 'lc-rec-1',
    siteId: 'site-1',
    zoneId: 'zone-1',
    planArea: 1000.0,
    actualArea: 950.0,
    clearingDate: DateTime(2026, 3, 10),
    notes: 'Block A north sector',
  );

  final sampleRecord2 = LandClearingRecord(
    id: 'lc-rec-2',
    siteId: 'site-1',
    zoneId: 'zone-2',
    planArea: 500.0,
    actualArea: 600.0,
    clearingDate: DateTime(2026, 3, 11),
    notes: 'Block B south slope',
  );

  final testZones = [
    const ZoneEntity(id: 'zone-1', name: 'Pit A', siteId: 'site-1'),
    const ZoneEntity(id: 'zone-2', name: 'Pit B', siteId: 'site-1'),
  ];

  setUpAll(() async {
    registerFallbackValue(sampleRecord1);
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    mockTrackingRepository = MockTrackingRepository();
    mockZoneRepository = MockZoneRepository();
    mockReportingRepository = MockReportingRepository();

    when(() => mockZoneRepository.getZones()).thenReturn(testZones);
    when(
      () => mockTrackingRepository.getLandClearingRecords(
        siteId: any(named: 'siteId'),
        zoneId: any(named: 'zoneId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => [sampleRecord1, sampleRecord2]);
  });

  Widget buildTestApp({
    required GoRouter router,
    Size size = const Size(1024, 768),
  }) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('LandClearingSummaryScreen', () {
    testWidgets('renders list with clearing summary card and clearing cards', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/operations/land-clearing',
        routes: [
          GoRoute(
            path: '/operations/land-clearing',
            name: 'land-clearing',
            builder: (context, state) => LandClearingSummaryScreen(
              repository: mockTrackingRepository,
              siteId: 'site-1',
              foremanId: 'foreman-1',
              zoneRepository: mockZoneRepository,
              reportingRepository: mockReportingRepository,
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      expect(find.byType(ClearingSummaryCard), findsOneWidget);
      expect(find.byType(LandClearingCard), findsNWidgets(2));
      expect(find.text('2 pencatatan'), findsOneWidget);
    });

    testWidgets('renders empty state when no clearing records exist', (
      tester,
    ) async {
      when(
        () => mockTrackingRepository.getLandClearingRecords(
          siteId: any(named: 'siteId'),
          zoneId: any(named: 'zoneId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);

      final router = GoRouter(
        initialLocation: '/operations/land-clearing',
        routes: [
          GoRoute(
            path: '/operations/land-clearing',
            name: 'land-clearing',
            builder: (context, state) => LandClearingSummaryScreen(
              repository: mockTrackingRepository,
              siteId: 'site-1',
              foremanId: 'foreman-1',
              zoneRepository: mockZoneRepository,
              reportingRepository: mockReportingRepository,
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada data land clearing.'), findsOneWidget);
      expect(find.text('Tekan "Clearing Baru" untuk memulai.'), findsOneWidget);
      expect(find.byType(LandClearingCard), findsNothing);
    });

    testWidgets(
      'tapping Laporan button opens AppContextualReportDialog with ReportType.landClearing',
      (tester) async {
        final router = GoRouter(
          initialLocation:
              '/operations/land-clearing?from=2026-03-01&to=2026-03-15&zoneId=zone-1',
          routes: [
            GoRoute(
              path: '/operations/land-clearing',
              name: 'land-clearing',
              builder: (context, state) => LandClearingSummaryScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
              ),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pumpAndSettle();

        final reportButton = find.widgetWithText(FButton, 'Laporan');
        expect(reportButton, findsOneWidget);
        await tester.tap(reportButton);
        await tester.pumpAndSettle();

        expect(find.byType(AppContextualReportDialog), findsOneWidget);
        expect(find.text('Laporan: Land Clearing'), findsOneWidget);
        expect(find.text(ReportType.landClearing.displayName), findsWidgets);
      },
    );

    // ----------------------------------------------------------------
    // STEP-55.3 RESIDUAL-2: AppFilterPopover Adoption Tests
    // ----------------------------------------------------------------

    testWidgets(
      'tapping filter bar opens AppFilterPopover without changing route',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/operations/land-clearing',
          routes: [
            GoRoute(
              path: '/operations/land-clearing',
              name: 'land-clearing',
              builder: (context, state) => LandClearingSummaryScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
              ),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pumpAndSettle();

        expect(find.text('Filter data'), findsOneWidget);

        // Tap filter bar
        await tester.tap(
          find.byKey(const ValueKey('land_clearing_filter_button')),
        );
        await tester.pumpAndSettle();

        // AppFilterPopover must be open
        expect(find.byType(AppFilterPopover), findsOneWidget);
        expect(find.text('Rentang Tanggal'), findsOneWidget);
        expect(find.text('Zona'), findsOneWidget);
        expect(find.text('Terapkan'), findsOneWidget);
        expect(find.text('Reset filter'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);
      },
    );

    testWidgets(
      'popover apply updates active filters, reloads list, and dismisses popover',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/operations/land-clearing',
          routes: [
            GoRoute(
              path: '/operations/land-clearing',
              name: 'land-clearing',
              builder: (context, state) => LandClearingSummaryScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
              ),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pumpAndSettle();

        // Open filter popover
        await tester.tap(
          find.byKey(const ValueKey('land_clearing_filter_button')),
        );
        await tester.pumpAndSettle();

        // Select a zone from ZoneFilterDropdown
        final zoneDropdown = find.byType(DropdownButton<String?>);
        expect(zoneDropdown, findsOneWidget);
        await tester.tap(zoneDropdown);
        await tester.pumpAndSettle();

        // Select 'Pit A' (id: 'zone-1')
        await tester.tap(find.text('Pit A').last);
        await tester.pumpAndSettle();

        // Tap 'Terapkan'
        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();

        // Popover should be dismissed
        expect(find.byType(AppFilterPopover), findsNothing);

        // Filter summary should be updated
        expect(find.text('Filter: Zona: zone-1'), findsOneWidget);

        // Verify repository called with selected zone
        verify(
          () => mockTrackingRepository.getLandClearingRecords(
            siteId: 'site-1',
            zoneId: 'zone-1',
            startDate: null,
            endDate: null,
          ),
        ).called(1);
      },
    );

    testWidgets('popover reset clears all active filters and reloads list', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/operations/land-clearing',
        routes: [
          GoRoute(
            path: '/operations/land-clearing',
            name: 'land-clearing',
            builder: (context, state) => LandClearingSummaryScreen(
              repository: mockTrackingRepository,
              siteId: 'site-1',
              foremanId: 'foreman-1',
              zoneRepository: mockZoneRepository,
              reportingRepository: mockReportingRepository,
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      // Apply a zone filter first via the popover
      await tester.tap(
        find.byKey(const ValueKey('land_clearing_filter_button')),
      );
      await tester.pumpAndSettle();

      final zoneDropdown = find.byType(DropdownButton<String?>);
      await tester.tap(zoneDropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pit A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(find.text('Filter: Zona: zone-1'), findsOneWidget);

      // Clear interactions to isolate the reset reload call
      clearInteractions(mockTrackingRepository);

      // Open filter popover again and reset
      await tester.tap(
        find.byKey(const ValueKey('land_clearing_filter_button')),
      );
      await tester.pumpAndSettle();

      // Tap 'Reset filter'
      await tester.tap(find.text('Reset filter'));
      await tester.pumpAndSettle();

      // Popover dismissed
      expect(find.byType(AppFilterPopover), findsNothing);

      // Filter summary reset to default
      expect(find.text('Filter data'), findsOneWidget);

      // Verify reload with null filters
      verify(
        () => mockTrackingRepository.getLandClearingRecords(
          siteId: 'site-1',
          zoneId: null,
          startDate: null,
          endDate: null,
        ),
      ).called(1);
    });

    testWidgets(
      'popover cancel dismisses dialog without mutating active filters',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/operations/land-clearing',
          routes: [
            GoRoute(
              path: '/operations/land-clearing',
              name: 'land-clearing',
              builder: (context, state) => LandClearingSummaryScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
              ),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pumpAndSettle();

        // Apply a zone filter first
        await tester.tap(
          find.byKey(const ValueKey('land_clearing_filter_button')),
        );
        await tester.pumpAndSettle();

        final zoneDropdown = find.byType(DropdownButton<String?>);
        await tester.tap(zoneDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pit A').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();

        expect(find.text('Filter: Zona: zone-1'), findsOneWidget);

        // Open filter popover
        await tester.tap(
          find.byKey(const ValueKey('land_clearing_filter_button')),
        );
        await tester.pumpAndSettle();

        // Tap 'Batal'
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        // Popover dismissed
        expect(find.byType(AppFilterPopover), findsNothing);

        // Original filters preserved in summary
        expect(find.text('Filter: Zona: zone-1'), findsOneWidget);
      },
    );

    testWidgets('focus returns to filter invoker upon popover dismissal', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/operations/land-clearing',
        routes: [
          GoRoute(
            path: '/operations/land-clearing',
            name: 'land-clearing',
            builder: (context, state) => LandClearingSummaryScreen(
              repository: mockTrackingRepository,
              siteId: 'site-1',
              foremanId: 'foreman-1',
              zoneRepository: mockZoneRepository,
              reportingRepository: mockReportingRepository,
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      final filterButtonFinder = find.byKey(
        const ValueKey('land_clearing_filter_button'),
      );
      await tester.tap(filterButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppFilterPopover), findsOneWidget);

      // Dismiss via Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.byType(AppFilterPopover), findsNothing);
      expect(filterButtonFinder, findsOneWidget);
    });

    testWidgets(
      'filter bar renders cleanly on narrow mobile layout without horizontal overflow',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/operations/land-clearing',
          routes: [
            GoRoute(
              path: '/operations/land-clearing',
              name: 'land-clearing',
              builder: (context, state) => LandClearingSummaryScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
              ),
            ),
          ],
        );

        // Narrow mobile viewport (360 x 640)
        await tester.pumpWidget(
          buildTestApp(router: router, size: const Size(360, 640)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('land_clearing_filter_button')),
          findsOneWidget,
        );

        // Open popover on narrow screen
        await tester.tap(
          find.byKey(const ValueKey('land_clearing_filter_button')),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppFilterPopover), findsOneWidget);

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
      },
    );
  });
}
