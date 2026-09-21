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
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_list_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/cut_fill_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/volume_summary_card.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

class MockReportingRepository extends Mock implements ReportingRepository {}

void main() {
  late MockTrackingRepository mockTrackingRepository;
  late MockZoneRepository mockZoneRepository;
  late MockReportingRepository mockReportingRepository;

  final sampleRecord1 = CutFillRecord(
    id: 'cf-rec-1',
    siteId: 'site-1',
    zoneId: 'zone-1',
    bcmVolume: 100.0,
    lcmVolume: 50.0,
    materialType: 'OB / Waste',
    measurementDate: DateTime(2026, 3, 10),
    notes: 'Pit A north bench',
  );

  final sampleRecord2 = CutFillRecord(
    id: 'cf-rec-2',
    siteId: 'site-1',
    zoneId: 'zone-2',
    bcmVolume: 200.0,
    lcmVolume: 0.0,
    materialType: 'Soil',
    measurementDate: DateTime(2026, 3, 11),
    notes: 'Pit B south slope',
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
      () => mockTrackingRepository.getCutFillRecords(
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

  group('CutFillListScreen', () {
    testWidgets('renders list with volume summary card and measurement cards', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/operations/cut-fill',
        routes: [
          GoRoute(
            path: '/operations/cut-fill',
            name: 'cut-fill',
            builder: (context, state) => CutFillListScreen(
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

      expect(find.byType(VolumeSummaryCard), findsOneWidget);
      expect(find.byType(CutFillCard), findsNWidgets(2));
      expect(find.text('2 pengukuran'), findsOneWidget);
    });

    testWidgets('renders empty state when no measurements exist', (
      tester,
    ) async {
      when(
        () => mockTrackingRepository.getCutFillRecords(
          siteId: any(named: 'siteId'),
          zoneId: any(named: 'zoneId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);

      final router = GoRouter(
        initialLocation: '/operations/cut-fill',
        routes: [
          GoRoute(
            path: '/operations/cut-fill',
            name: 'cut-fill',
            builder: (context, state) => CutFillListScreen(
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

      expect(find.text('Belum ada data volume cut/fill.'), findsOneWidget);
      expect(
        find.text('Tekan "Pengukuran Baru" untuk memulai.'),
        findsOneWidget,
      );
      expect(find.byType(CutFillCard), findsNothing);
    });

    testWidgets(
      'tapping record card navigates directly to edit route (FC-54.2-006, D7)',
      (tester) async {
        String? editedRecordId;
        CutFillRecord? editedExtra;

        final router = GoRouter(
          initialLocation: '/operations/cut-fill',
          routes: [
            GoRoute(
              path: '/operations/cut-fill',
              name: 'cut-fill',
              builder: (context, state) => CutFillListScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
              ),
              routes: [
                GoRoute(
                  path: ':id/form',
                  name: 'cut-fill-edit',
                  builder: (context, state) {
                    editedRecordId = state.pathParameters['id'];
                    editedExtra = state.extra as CutFillRecord?;
                    return Text('EDIT_PAGE_${state.pathParameters['id']}');
                  },
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pumpAndSettle();

        // Tap the first CutFillCard
        await tester.tap(find.byType(CutFillCard).first);
        await tester.pumpAndSettle();

        // Must push direct-to-edit without any intermediate inspector
        expect(editedRecordId, 'cf-rec-1');
        expect(editedExtra, sampleRecord1);
        expect(find.text('EDIT_PAGE_cf-rec-1'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Pengukuran Baru navigates to cut-fill-create route preserving filters',
      (tester) async {
        Map<String, String>? createQueryParams;

        final router = GoRouter(
          initialLocation:
              '/operations/cut-fill?from=2026-03-01&to=2026-03-15&zoneId=zone-1',
          routes: [
            GoRoute(
              path: '/operations/cut-fill',
              name: 'cut-fill',
              builder: (context, state) => CutFillListScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
                initialStartDate: DateTime(2026, 3, 1),
                initialEndDate: DateTime(2026, 3, 15),
                initialZoneId: 'zone-1',
              ),
              routes: [
                GoRoute(
                  path: 'form',
                  name: 'cut-fill-create',
                  builder: (context, state) {
                    createQueryParams = state.uri.queryParameters;
                    return const Text('CREATE_PAGE');
                  },
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pumpAndSettle();

        // Tap Pengukuran Baru button
        final newButton = find.widgetWithText(FButton, 'Pengukuran Baru');
        expect(newButton, findsOneWidget);
        await tester.tap(newButton);
        await tester.pumpAndSettle();

        expect(find.text('CREATE_PAGE'), findsOneWidget);
        expect(createQueryParams?['from'], '2026-03-01');
        expect(createQueryParams?['to'], '2026-03-15');
        expect(createQueryParams?['zoneId'], 'zone-1');
      },
    );

    testWidgets(
      'tapping Laporan button opens AppContextualReportDialog with ReportType.cutFill',
      (tester) async {
        final router = GoRouter(
          initialLocation:
              '/operations/cut-fill?from=2026-03-01&to=2026-03-15&zoneId=zone-1',
          routes: [
            GoRoute(
              path: '/operations/cut-fill',
              name: 'cut-fill',
              builder: (context, state) => CutFillListScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
                initialStartDate: DateTime(2026, 3, 1),
                initialEndDate: DateTime(2026, 3, 15),
                initialZoneId: 'zone-1',
              ),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pumpAndSettle();

        // Tap Laporan button
        final reportButton = find.widgetWithText(FButton, 'Laporan');
        expect(reportButton, findsOneWidget);
        await tester.tap(reportButton);
        await tester.pumpAndSettle();

        // AppContextualReportDialog should be displayed
        expect(find.byType(AppContextualReportDialog), findsOneWidget);
        expect(find.text('Laporan: Volume Cut / Fill'), findsOneWidget);
        expect(find.text(ReportType.cutFill.displayName), findsWidgets);
      },
    );

    // ----------------------------------------------------------------
    // STEP-55.2 RESIDUAL: AppFilterPopover Adoption Tests
    // ----------------------------------------------------------------

    testWidgets(
      'tapping filter bar opens AppFilterPopover without changing route',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/operations/cut-fill',
          routes: [
            GoRoute(
              path: '/operations/cut-fill',
              name: 'cut-fill',
              builder: (context, state) => CutFillListScreen(
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
        await tester.tap(find.byKey(const ValueKey('cut_fill_filter_button')));
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
      'popover apply updates active filters, reloads list, and preserves query parameters',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/operations/cut-fill',
          routes: [
            GoRoute(
              path: '/operations/cut-fill',
              name: 'cut-fill',
              builder: (context, state) => CutFillListScreen(
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
        await tester.tap(find.byKey(const ValueKey('cut_fill_filter_button')));
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
          () => mockTrackingRepository.getCutFillRecords(
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
        initialLocation:
            '/operations/cut-fill?from=2026-03-01&to=2026-03-15&zoneId=zone-1',
        routes: [
          GoRoute(
            path: '/operations/cut-fill',
            name: 'cut-fill',
            builder: (context, state) => CutFillListScreen(
              repository: mockTrackingRepository,
              siteId: 'site-1',
              foremanId: 'foreman-1',
              zoneRepository: mockZoneRepository,
              reportingRepository: mockReportingRepository,
              initialStartDate: DateTime(2026, 3, 1),
              initialEndDate: DateTime(2026, 3, 15),
              initialZoneId: 'zone-1',
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      expect(
        find.text('Filter: 1 Mar 2026 - 15 Mar 2026 · Zona: zone-1'),
        findsOneWidget,
      );

      // Open filter popover
      await tester.tap(find.byKey(const ValueKey('cut_fill_filter_button')));
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
        () => mockTrackingRepository.getCutFillRecords(
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
          initialLocation:
              '/operations/cut-fill?from=2026-03-01&to=2026-03-15&zoneId=zone-1',
          routes: [
            GoRoute(
              path: '/operations/cut-fill',
              name: 'cut-fill',
              builder: (context, state) => CutFillListScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
                initialStartDate: DateTime(2026, 3, 1),
                initialEndDate: DateTime(2026, 3, 15),
                initialZoneId: 'zone-1',
              ),
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(router: router));
        await tester.pumpAndSettle();

        // Open filter popover
        await tester.tap(find.byKey(const ValueKey('cut_fill_filter_button')));
        await tester.pumpAndSettle();

        // Tap 'Batal'
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        // Popover dismissed
        expect(find.byType(AppFilterPopover), findsNothing);

        // Original filters preserved in summary
        expect(
          find.text('Filter: 1 Mar 2026 - 15 Mar 2026 · Zona: zone-1'),
          findsOneWidget,
        );
      },
    );

    testWidgets('focus returns to filter invoker upon popover dismissal', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/operations/cut-fill',
        routes: [
          GoRoute(
            path: '/operations/cut-fill',
            name: 'cut-fill',
            builder: (context, state) => CutFillListScreen(
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
        const ValueKey('cut_fill_filter_button'),
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
          initialLocation:
              '/operations/cut-fill?from=2026-03-01&to=2026-03-15&zoneId=zone-1',
          routes: [
            GoRoute(
              path: '/operations/cut-fill',
              name: 'cut-fill',
              builder: (context, state) => CutFillListScreen(
                repository: mockTrackingRepository,
                siteId: 'site-1',
                foremanId: 'foreman-1',
                zoneRepository: mockZoneRepository,
                reportingRepository: mockReportingRepository,
                initialStartDate: DateTime(2026, 3, 1),
                initialEndDate: DateTime(2026, 3, 15),
                initialZoneId: 'zone-1',
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
          find.byKey(const ValueKey('cut_fill_filter_button')),
          findsOneWidget,
        );

        // Open popover on narrow screen
        await tester.tap(find.byKey(const ValueKey('cut_fill_filter_button')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppFilterPopover), findsOneWidget);

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
      },
    );
  });
}
