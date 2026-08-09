import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
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

class MockEquipmentCheckRepository extends Mock
    implements EquipmentCheckRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  late MockEquipmentCheckRepository mockRepository;

  const tSiteId = '00000000-0000-0000-0000-000000000001';
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
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: EquipmentHistoryScreen(
          repository: mockRepository,
          siteId: tSiteId,
          foremanId: tForemanId,
        ),
      ),
    );
  }

  group('EquipmentHistoryScreen Widget Tests', () {
    testWidgets(
      'should render history screen, search bar, filter chips, FAB, and equipment cards',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Riwayat Inspeksi Peralatan'), findsOneWidget);
        expect(find.byKey(const Key('equipment_search_field')), findsOneWidget);
        expect(find.byKey(const Key('filter_equipment_all')), findsOneWidget);
        expect(find.byKey(const Key('filter_status_all')), findsOneWidget);
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

    testWidgets('should filter history list by equipment type chip selection', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsNWidgets(2));

      // Tap Drone filter chip
      final droneChip = find.byKey(const Key('filter_equipment_drone'));
      await tester.tap(droneChip);
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsOneWidget);
      expect(find.text('S/N: GNSS-1001'), findsNothing);
    });

    testWidgets('should filter history list by status chip selection', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsNWidgets(2));

      // Tap Flagged status filter chip
      final flaggedChip = find.byKey(const Key('filter_status_flagged'));
      await tester.tap(flaggedChip);
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentCheckCard), findsOneWidget);
      expect(find.text('S/N: DRONE-2002'), findsOneWidget);
      expect(find.text('S/N: GNSS-1001'), findsNothing);
    });

    testWidgets(
      'should expand equipment check card to reveal SOP items breakdown on expansion tile tap',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final expansionTileHeader = find.text('SOP Checklist: 2 / 2 Lolos');
        expect(expansionTileHeader, findsOneWidget);

        await tester.tap(expansionTileHeader);
        await tester.pumpAndSettle();

        expect(find.text('Level Baterai & Catu Daya'), findsOneWidget);
        expect(find.text('Koneksi Antena & Kabel RTK'), findsOneWidget);
      },
    );

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
        expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      },
    );
  });
}
