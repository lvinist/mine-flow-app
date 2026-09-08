import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/core/domain/entities/user_entity.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_page.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/status_toggle_chips.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';

import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

/// Fake returning a real-UUID roster, mirroring the users table the app
/// now loads through `AuthRepository.getSiteRoster` (STEP-48.26 R-6).
class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Future<List<UserEntity>> getSiteRoster({String? siteId}) async => const [
    UserEntity(
      id: 'a1aaaaaa-1111-4111-8111-111111111111',
      email: 'kru1@mineflow.dev',
      name: 'Alex Supervisor',
      role: 'supervisor',
      siteId: 'site-001',
    ),
    UserEntity(
      id: 'b2bbbbbb-2222-4222-8222-222222222222',
      email: 'kru2@mineflow.dev',
      name: 'Frank Foreman',
      role: 'foreman',
      siteId: 'site-001',
    ),
  ];
}

class MockGoRouter extends Mock implements GoRouter {}

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

  late MockGoRouter mockGoRouter;

  setUp(() {
    mockRepository = MockAttendanceRepository();
    mockGoRouter = MockGoRouter();
    when(
      () => mockRepository.getAttendanceForDate(
        any(),
        siteId: any(named: 'siteId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.saveAttendanceBatch(any()),
    ).thenAnswer((_) async {});
  });

  Widget buildTestWidget({AuthRepository? authRepository}) {
    return MaterialApp(
      builder: (context, child) =>
          FTheme(data: FTheme.neutral.light.touch, child: child!),
      home: InheritedGoRouter(
        goRouter: mockGoRouter,
        child: AttendanceFormPage(
          repository: mockRepository,
          authRepository: authRepository,
          siteId: 'site-001',
          initialDate: DateTime(2026, 7, 28),
        ),
      ),
    );
  }

  group('AttendanceFormPage Widget Tests (Bulk Edit)', () {
    testWidgets(
      'should render empty state for bulk editing when no records exist',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Input Absensi Kru'), findsOneWidget);
        expect(find.text('Mulai Absensi Massal'), findsOneWidget);
        // CF-015: the synthetic seed is now gated behind kDebugMode.
        expect(find.text('Muat Daftar Kru Default (Debug)'), findsOneWidget);
      },
    );

    testWidgets(
      'should load default roster when "Muat Daftar Kru Default" is tapped',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestWidget(authRepository: FakeAuthRepository()),
        );
        await tester.pumpAndSettle();

        final loadButton = find.text('Muat Daftar Kru Default (Debug)');
        await tester.tap(loadButton);
        await tester.pumpAndSettle();

        // The seeder now loads the real site roster (users.id UUIDs) through
        // the auth repository instead of fabricating KRU-00N codes
        // (STEP-48.26 R-6).
        expect(find.text('Alex Supervisor'), findsWidgets);
        expect(
          find.textContaining('ID: a1aaaaaa-1111-4111-8111-111111111111'),
          findsOneWidget,
        );
        expect(find.textContaining('Simpan Absensi'), findsOneWidget);
      },
    );
    testWidgets('should update summary counts when status chip is toggled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tDate = DateTime(2026, 7, 28);
      when(
        () => mockRepository.getAttendanceForDate(tDate, siteId: 'site-001'),
      ).thenAnswer(
        (_) async => [
          AttendanceRecord(
            id: 'att-001',
            siteId: 'site-001',
            userId: 'KRU-001',
            date: tDate,
            status: AttendanceStatus.present,
          ),
          AttendanceRecord(
            id: 'att-002',
            siteId: 'site-001',
            userId: 'KRU-002',
            date: tDate,
            status: AttendanceStatus.absent,
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final statusToggleWidget = find.byType(StatusToggleChips).first;
      final alphaChipInRoster = find.descendant(
        of: statusToggleWidget,
        matching: find.text('Alpha'),
      );

      expect(alphaChipInRoster, findsOneWidget);

      var alphaSemantics = tester.widget<Semantics>(
        find
            .ancestor(of: alphaChipInRoster, matching: find.byType(Semantics))
            .first,
      );
      expect(alphaSemantics.properties.selected, false);

      await tester.tap(alphaChipInRoster);
      await tester.pumpAndSettle();

      alphaSemantics = tester.widget<Semantics>(
        find
            .ancestor(of: alphaChipInRoster, matching: find.byType(Semantics))
            .first,
      );
      expect(alphaSemantics.properties.selected, true);
    });

    testWidgets('should call saveAttendanceBatch when save button is pressed', (
      tester,
    ) async {
      final tDate = DateTime(2026, 7, 28);
      when(
        () => mockRepository.getAttendanceForDate(tDate, siteId: 'site-001'),
      ).thenAnswer(
        (_) async => [
          AttendanceRecord(
            id: 'att-001',
            siteId: 'site-001',
            userId: 'KRU-001',
            date: tDate,
            status: AttendanceStatus.present,
          ),
          AttendanceRecord(
            id: 'att-002',
            siteId: 'site-001',
            userId: 'KRU-002',
            date: tDate,
            status: AttendanceStatus.absent,
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan Absensi (2 Kru)');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(() => mockRepository.saveAttendanceBatch(any())).called(1);
    });
  });
}
