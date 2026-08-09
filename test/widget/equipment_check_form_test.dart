import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_check_form_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/condition_summary_badge.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_type_tabs.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/sop_checklist_item_card.dart';

class MockEquipmentCheckRepository extends Mock
    implements EquipmentCheckRepository {}

class FakeEquipmentCheck extends Fake implements EquipmentCheck {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    registerFallbackValue(FakeEquipmentCheck());
  });

  late MockEquipmentCheckRepository mockRepository;

  const tSiteId = '00000000-0000-0000-0000-000000000001';
  const tForemanId = 'foreman-001';

  setUp(() {
    mockRepository = MockEquipmentCheckRepository();
    when(
      () => mockRepository.saveEquipmentCheck(any()),
    ).thenAnswer((_) async => {});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) =>
          FTheme(data: FTheme.neutral.light.touch, child: child!),
      home: EquipmentCheckFormScreen(
        repository: mockRepository,
        siteId: tSiteId,
        foremanId: tForemanId,
      ),
    );
  }

  group('EquipmentCheckFormScreen Widget Tests', () {
    testWidgets(
      'should render equipment tabs, check type toggle, summary badge, and SOP cards',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Inspeksi SOP Peralatan'), findsOneWidget);
        expect(find.byType(EquipmentTypeTabs), findsOneWidget);
        expect(find.text('GNSS Receiver'), findsOneWidget);
        expect(find.text('Total Station'), findsOneWidget);
        expect(find.text('Drone / UAV'), findsOneWidget);

        expect(find.byType(ConditionSummaryBadge), findsOneWidget);
        expect(find.text('OPERASIONAL (PASSED)'), findsOneWidget);
        expect(find.text('5 dari 5 Item SOP Lolos Check'), findsOneWidget);

        expect(find.byType(SopChecklistItemCard), findsNWidgets(5));
        expect(find.text('Level Baterai & Catu Daya'), findsOneWidget);
        expect(find.text('DAFTAR CEK KELAYAKAN SOP'), findsOneWidget);
      },
    );

    testWidgets(
      'should update SOP checklist items when switching equipment type tabs',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final totalStationTab = find.text('Total Station');
        expect(totalStationTab, findsOneWidget);

        await tester.tap(totalStationTab);
        await tester.pumpAndSettle();

        expect(find.text('Levelling Nivo & Optical Plummet'), findsOneWidget);
        expect(find.text('Tegangan Baterai Utama & Cadangan'), findsOneWidget);
      },
    );

    testWidgets(
      'should update status to FLAGGED when an SOP item is marked FAIL',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('OPERASIONAL (PASSED)'), findsOneWidget);

        // Find the first FAIL button
        final failButtons = find.text('FAIL');
        expect(failButtons, findsNWidgets(5));

        await tester.tap(failButtons.first);
        await tester.pumpAndSettle();

        expect(find.text('PERLU MAINTENANCE / FLAGGED'), findsOneWidget);
        expect(find.text('4 dari 5 Item SOP Lolos Check'), findsOneWidget);
        expect(
          find.text('Catatan Kerusakan / Kendala (Wajib)'),
          findsOneWidget,
        );
      },
    );

    testWidgets('should save equipment check when submit button is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final serialNumberField = find.widgetWithText(
        TextField,
        'Nomor Seri Alat / ID Unit',
      );
      expect(serialNumberField, findsOneWidget);

      await tester.enterText(serialNumberField, 'GNSS-TEST-99');
      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(
        FButton,
        'Simpan Inspeksi SOP (5/5 Lolos)',
      );
      expect(submitButton, findsOneWidget);

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      verify(() => mockRepository.saveEquipmentCheck(any())).called(1);
      expect(
        find.text('Pemeriksaan SOP berhasil disimpan offline'),
        findsOneWidget,
      );
    });

    testWidgets(
      'should contain zero ElevatedButton, Card, or TextButton widgets (Impeccable purge)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.byType(Card), findsNothing);
        expect(find.byType(TextButton), findsNothing);
      },
    );
  });
}
