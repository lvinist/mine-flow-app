import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_history_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_check_card.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class MockEquipmentCheckRepository extends Mock
    implements EquipmentCheckRepository {}

class MockReportingRepository extends Mock implements ReportingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  late MockEquipmentCheckRepository mockRepository;
  late MockReportingRepository mockReportingRepository;
  late MockZoneRepository mockZoneRepository;

  const tSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  const tForemanId = 'foreman-001';

  final tCheck1 = EquipmentCheck(
    id: 'check-1',
    siteId: tSiteId,
    foremanId: tForemanId,
    equipmentType: EquipmentType.gnss,
    serialNumber: 'GNSS-1001',
    checkTime: DateTime(2026, 7, 18, 10, 0),
    checkType: CheckType.preWork,
    status: CheckStatus.passed,
    isOperational: true,
    checklist: const [
      CheckItem(
        id: 'gnss_battery',
        label: 'Level Baterai & Catu Daya',
        isPassed: true,
      ),
      CheckItem(
        id: 'gnss_antenna',
        label: 'Koneksi Antena & Kabel RTK',
        isPassed: true,
      ),
    ],
  );

  final tCheck2 = EquipmentCheck(
    id: 'check-2',
    siteId: tSiteId,
    foremanId: 'foreman-102',
    equipmentType: EquipmentType.drone,
    serialNumber: 'DRONE-2002',
    checkTime: DateTime(2026, 7, 18, 11, 0),
    checkType: CheckType.postWork,
    status: CheckStatus.flagged,
    isOperational: false,
    remarks: 'Baling-baling retak',
    checklist: const [
      CheckItem(
        id: 'drone_propellers',
        label: 'Inspeksi Baling-baling (Propellers)',
        isPassed: false,
        remarks: 'Retak pada blade kanan',
      ),
      CheckItem(
        id: 'drone_battery',
        label: 'Tegangan Baterai Terbang & Sel',
        isPassed: true,
      ),
    ],
  );

  setUp(() {
    mockRepository = MockEquipmentCheckRepository();
    mockReportingRepository = MockReportingRepository();
    mockZoneRepository = MockZoneRepository();
    when(() => mockZoneRepository.getZones()).thenReturn([]);
    when(
      () => mockRepository.getEquipmentChecks(
        siteId: any(named: 'siteId'),
        equipmentType: any(named: 'equipmentType'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((invocation) async {
      final typeFilter =
          invocation.namedArguments[#equipmentType] as EquipmentType?;
      if (typeFilter != null) {
        return [
          tCheck1,
          tCheck2,
        ].where((c) => c.equipmentType == typeFilter).toList();
      }
      return [tCheck1, tCheck2];
    });
  });

  Widget buildTestWidget() {
    return MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) =>
          FTheme(data: FTheme.neutral.light.touch, child: child!),
      home: EquipmentHistoryScreen(
        repository: mockRepository,
        siteId: tSiteId,
        foremanId: tForemanId,
        reportingRepository: mockReportingRepository,
        zoneRepository: mockZoneRepository,
      ),
    );
  }

  group('EquipmentHistoryScreen Widget Tests (STEP-55.7)', () {
    testWidgets(
      'should render history screen, search bar, filter button, FAB, and equipment cards',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Riwayat Inspeksi Peralatan'), findsOneWidget);
        expect(find.byKey(const Key('equipment_search_field')), findsOneWidget);
        expect(
          find.byKey(const Key('equipment_filter_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('create_new_equipment_check_fab')),
          findsOneWidget,
        );

        expect(find.byType(EquipmentCheckCard), findsNWidgets(2));
        expect(find.textContaining('GNSS Receiver'), findsWidgets);
        expect(find.textContaining('Drone / UAV'), findsWidgets);
        expect(find.text('S/N: GNSS-1001'), findsOneWidget);
        expect(find.text('S/N: DRONE-2002'), findsOneWidget);
      },
    );

    testWidgets(
      'should filter history list by equipment type via filter popover',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(EquipmentCheckCard), findsNWidgets(2));

        // Open filter popover
        await tester.tap(find.byKey(const Key('equipment_filter_button')));
        await tester.pumpAndSettle();

        // Tap Drone filter button inside popover
        final droneOption = find.byKey(const Key('filter_equipment_drone'));
        expect(droneOption, findsOneWidget);
        await tester.tap(droneOption);
        await tester.pumpAndSettle();

        // Apply filter
        await tester.tap(find.text('Terapkan'));
        await tester.pumpAndSettle();

        expect(find.byType(EquipmentCheckCard), findsOneWidget);
        expect(find.text('S/N: DRONE-2002'), findsOneWidget);
        expect(find.text('S/N: GNSS-1001'), findsNothing);
      },
    );

    testWidgets('should filter history list by status via filter popover', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsNWidgets(2));

      // Open filter popover
      await tester.tap(find.byKey(const Key('equipment_filter_button')));
      await tester.pumpAndSettle();

      // Tap Flagged status button
      final flaggedOption = find.byKey(const Key('filter_status_flagged'));
      expect(flaggedOption, findsOneWidget);
      await tester.tap(flaggedOption);
      await tester.pumpAndSettle();

      // Apply filter
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsOneWidget);
      expect(find.text('S/N: GNSS-1001'), findsNothing);

      // Re-open filter popover and switch to Passed status
      await tester.tap(find.byKey(const Key('equipment_filter_button')));
      await tester.pumpAndSettle();

      final passedOption = find.byKey(const Key('filter_status_passed'));
      expect(passedOption, findsOneWidget);
      await tester.tap(passedOption);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsOneWidget);
      expect(find.text('S/N: GNSS-1001'), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsNothing);

      // Re-open filter popover, select Flagged, but tap Batal (cancel)
      await tester.tap(find.byKey(const Key('equipment_filter_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter_status_flagged')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // State is unchanged (Passed filter remains active)
      expect(find.byType(EquipmentCheckCard), findsOneWidget);
      expect(find.text('S/N: GNSS-1001'), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsNothing);

      // Dismiss status filter via active filter chip
      expect(find.text('Status: Passed'), findsOneWidget);
      await tester.tap(find.text('Status: Passed'));
      await tester.pumpAndSettle();

      // Filter cleared via chip; both items appear
      expect(find.byType(EquipmentCheckCard), findsNWidgets(2));
      expect(find.text('S/N: GNSS-1001'), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsOneWidget);

      // Re-apply Flagged filter then test Reset filter button inside popover
      await tester.tap(find.byKey(const Key('equipment_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter_status_flagged')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();
      expect(find.byType(EquipmentCheckCard), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsOneWidget);

      // Re-open filter popover and reset filter
      await tester.tap(find.byKey(const Key('equipment_filter_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset filter'));
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsNWidgets(2));
      expect(find.text('S/N: GNSS-1001'), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsOneWidget);
    });

    testWidgets(
      'should display summary badge and navigate cue on equipment check card (FC-54.7-001)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final summaryText = find.text('SOP Checklist: 2 / 2 Lolos');
        expect(summaryText, findsOneWidget);
        expect(find.byIcon(LucideIcons.chevronRight), findsWidgets);
      },
    );

    testWidgets('should filter history list by search query with debounce', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsNWidgets(2));

      // Type in search field
      await tester.enterText(
        find.byKey(const Key('equipment_search_field')),
        'DRONE-2002',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsOneWidget);
      expect(find.text('S/N: GNSS-1001'), findsNothing);
    });

    testWidgets(
      'should display empty state message when no equipment checks exist',
      (tester) async {
        when(
          () => mockRepository.getEquipmentChecks(
            siteId: any(named: 'siteId'),
            equipmentType: any(named: 'equipmentType'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(EquipmentCheckCard), findsNothing);
        expect(
          find.text('Belum ada riwayat inspeksi peralatan.'),
          findsOneWidget,
        );
        expect(find.byIcon(LucideIcons.boxes), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Laporan button opens AppContextualReportDialog for equipment check preserving list state (FC-54.7-005)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // 1. Enter a search query to establish list state
        await tester.enterText(
          find.byKey(const Key('equipment_search_field')),
          'DRONE-2002',
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(find.byType(EquipmentCheckCard), findsOneWidget);
        expect(find.text('S/N: DRONE-2002'), findsOneWidget);

        // 2. Tap Laporan button
        final reportButton = find.byKey(const Key('equipment_report_button'));
        expect(reportButton, findsOneWidget);
        await tester.tap(reportButton);
        await tester.pumpAndSettle();

        // 3. AppContextualReportDialog should open contextually in front of list
        expect(find.byType(AppContextualReportDialog), findsOneWidget);
        expect(find.text('Laporan: Inspeksi Peralatan'), findsOneWidget);

        // 4. Background list card and search text remain mounted and preserved
        expect(find.byType(EquipmentCheckCard), findsOneWidget);
        expect(find.text('DRONE-2002'), findsWidgets);
      },
    );
  });
}
