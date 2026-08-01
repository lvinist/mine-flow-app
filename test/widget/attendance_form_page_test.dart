import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_page.dart';

import 'package:forui/forui.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(
      AttendanceRecord(
        id: 'fallback-id',
        siteId: 'site-01',
        userId: 'KRU-001',
        date: DateTime(2026, 1, 1),
        status: AttendanceStatus.present,
      ),
    );
  });

  late MockAttendanceRepository mockRepository;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    when(() => mockRepository.getAttendanceForDate(any(), siteId: any(named: 'siteId')))
        .thenAnswer((_) async => []);
    when(() => mockRepository.saveAttendanceBatch(any()))
        .thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    return MaterialApp(
      builder: (context, child) => FTheme(
        data: FTheme.neutral.light.touch,
        child: child!,
      ),
      home: AttendanceFormPage(
        repository: mockRepository,
        siteId: 'site-001',
        initialDate: DateTime(2026, 7, 28),
      ),
    );
  }

  group('AttendanceFormPage Widget Tests (Bulk Edit)', () {
    testWidgets('should render empty state for bulk editing when no records exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Input Absensi Kru'), findsOneWidget);
      expect(find.text('Mulai Absensi Massal'), findsOneWidget);
      expect(find.text('Muat Daftar Kru Default'), findsOneWidget);
    });

    testWidgets('should load default roster when "Muat Daftar Kru Default" is tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final loadButton = find.text('Muat Daftar Kru Default');
      await tester.tap(loadButton);
      await tester.pumpAndSettle();

      expect(find.text('Pekerja 1'), findsWidgets);
      expect(find.text('Supervisor • ID: KRU-001'), findsOneWidget);
      expect(find.textContaining('Simpan Absensi'), findsOneWidget);
    });
  });
}
