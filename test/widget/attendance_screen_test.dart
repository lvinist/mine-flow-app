import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/app/theme/app_theme.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_screen.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_summary_card.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/crew_roster_item.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/status_toggle_chips.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(<AttendanceRecord>[]);
  });

  late MockAttendanceRepository mockRepository;

  final tDate = DateTime(2026, 7, 18);
  const tSiteId = '00000000-0000-0000-0000-000000000001';

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
    when(() => mockRepository.getAttendanceForDate(any(), siteId: any(named: 'siteId')))
        .thenAnswer((_) async => tRecords);
    when(() => mockRepository.saveAttendanceBatch(any()))
        .thenAnswer((_) async => {});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.light,
      home: AttendanceScreen(
        repository: mockRepository,
        initialSiteId: tSiteId,
        initialDate: tDate,
      ),
    );
  }

  group('AttendanceScreen Widget Tests', () {
    testWidgets('should render app bar, summary card, search field, and crew roster', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Absensi Kru Lapangan'), findsOneWidget);
      expect(find.byType(AttendanceSummaryCard), findsOneWidget);
      expect(find.text('Ringkasan Kehadiran'), findsOneWidget);
      expect(find.text('Cari Kru ID atau Catatan...'), findsOneWidget);

      expect(find.byType(CrewRosterItem), findsNWidgets(2));
      expect(find.text('Kru ID: KRU-001'), findsOneWidget);
      expect(find.text('Kru ID: KRU-002'), findsOneWidget);
    });

    testWidgets('should update summary counts when status chip is toggled', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final statusToggleWidget = find.byType(StatusToggleChips).first;
      final alphaChipInRoster = find.descendant(
        of: statusToggleWidget,
        matching: find.text('Alpha'),
      );

      expect(alphaChipInRoster, findsOneWidget);

      await tester.tap(alphaChipInRoster);
      await tester.pumpAndSettle();

      // Unsaved changes badge should appear in AppBar
      expect(find.text('Belum Disimpan'), findsOneWidget);
    });

    testWidgets('should filter crew roster when typing in search text field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CrewRosterItem), findsNWidgets(2));

      // Type 'KRU-001' into search bar
      await tester.enterText(find.byType(TextField), 'KRU-001');
      await tester.pumpAndSettle();

      expect(find.byType(CrewRosterItem), findsOneWidget);
      expect(find.text('Kru ID: KRU-001'), findsOneWidget);
      expect(find.text('Kru ID: KRU-002'), findsNothing);
    });

    testWidgets('should call saveAttendanceBatch when save button is pressed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Simpan Absensi (2 Kru)');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(() => mockRepository.saveAttendanceBatch(any())).called(1);
      expect(find.text('Absensi berhasil disimpan offline'), findsOneWidget);
    });

    testWidgets('should navigate dates when pressing next date arrow', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final forwardArrow = find.byIcon(Icons.arrow_forward_ios);
      expect(forwardArrow, findsOneWidget);

      await tester.tap(forwardArrow);
      await tester.pumpAndSettle();

      final expectedNextDate = tDate.add(const Duration(days: 1));
      verify(() => mockRepository.getAttendanceForDate(
            expectedNextDate,
            siteId: tSiteId,
          )).called(1);
    });
  });
}
