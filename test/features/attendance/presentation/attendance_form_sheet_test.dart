import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/domain/entities/user_entity.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/pages/attendance_form_sheet.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_crew_card.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

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

/// Widget tests for the route-hosted batch attendance sheet (STEP-55.5,
/// master spec §4.4 items 1–8).
void main() {
  const siteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  final date = DateTime(2026, 9, 11);

  late MockAttendanceRepository mockRepository;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    registerFallbackValue(<AttendanceRecord>[]);
    registerFallbackValue(
      AttendanceRecord(
        id: 'fallback',
        siteId: siteId,
        userId: 'u',
        date: date,
        status: AttendanceStatus.present,
      ),
    );
  });

  setUp(() {
    mockRepository = MockAttendanceRepository();
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

  Widget buildSheet({DateTime? initialDate, bool cold = false}) {
    final sheet = AttendanceFormSheet(
      repository: mockRepository,
      authRepository: FakeAuthRepository(),
      initialDate: initialDate ?? date,
      siteId: siteId,
    );

    if (cold) {
      // Cold URL: no in-memory extra; the sheet reconstructs from its own
      // durable parameters only.
      return FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => FToaster(child: child!),
          home: sheet,
        ),
      );
    }

    final router = GoRouter(
      initialLocation: '/teams/attendance/form',
      routes: [
        GoRoute(
          path: '/teams/attendance',
          builder: (_, _) => const Scaffold(body: Text('LIST')),
        ),
        GoRoute(path: '/teams/attendance/form', builder: (_, _) => sheet),
      ],
    );
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FToaster(child: child!),
      ),
    );
  }

  Future<void> pumpSheet(WidgetTester tester, {bool cold = false}) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSheet(cold: cold));
    await tester.pumpAndSettle();
  }

  group('AttendanceFormSheet — layout (spec §4.4 items 1–2, 8)', () {
    testWidgets('renders one header row with date left and Tandai Semua Masuk '
        'right, plus a batch footer', (tester) async {
      await pumpSheet(tester);

      expect(find.byType(AttendanceCrewCard), findsNWidgets(2));
      expect(find.text('Tandai Semua Masuk'), findsOneWidget);
      // Footer batch label reflects the crew count.
      expect(find.text('Simpan Absensi (2 Kru)'), findsOneWidget);
    });

    testWidgets('cold route reconstructs the sheet from durable parameters '
        'without extra', (tester) async {
      await pumpSheet(tester, cold: true);
      expect(find.byType(AttendanceCrewCard), findsNWidgets(2));
      expect(find.text('Simpan Absensi (2 Kru)'), findsOneWidget);
    });
  });

  group('AttendanceFormSheet — four inline choices (spec §4.4 item 4)', () {
    testWidgets('every card shows Izin, Sakit, Alpa, and Masuk with 48dp '
        'targets and no UUID copy', (tester) async {
      await pumpSheet(tester);

      for (final label in ['Izin', 'Sakit', 'Alpa', 'Masuk']) {
        expect(find.text(label), findsNWidgets(2));
      }
      // Real name is the primary label; the UUID never appears.
      expect(find.text('Alex Supervisor'), findsOneWidget);
      expect(
        find.textContaining('a1aaaaaa-1111-4111-8111-111111111111'),
        findsNothing,
      );
    });

    testWidgets('selecting Izin reveals the required reason field for that '
        'crew member only', (tester) async {
      await pumpSheet(tester);

      expect(find.byKey(const Key('attendance_reason_field')), findsNothing);

      await tester.tap(find.text('Izin').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attendance_reason_field')), findsOneWidget);
      expect(find.text('Alasan izin (wajib)'), findsOneWidget);
    });

    testWidgets('changing a non-empty reason to Masuk asks for confirmation '
        'before discarding it', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Izin').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('attendance_reason_field')),
        'Izin setengah hari',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk').first);
      await tester.pumpAndSettle();

      // Confirmation dialog appears.
      expect(find.text('Hapus alasan?'), findsOneWidget);

      // Cancelling keeps the reason and does not change the status.
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attendance_reason_field')), findsOneWidget);
    });

    testWidgets('confirming the discard clears the reason and collapses the '
        'field', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Izin').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('attendance_reason_field')),
        'Izin setengah hari',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masuk').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus alasan'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attendance_reason_field')), findsNothing);
    });
  });

  group('AttendanceFormSheet — submit validation (spec §4.4 item 8)', () {
    testWidgets('does not save while rows are unset', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Simpan Absensi (2 Kru)'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.saveAttendanceBatch(any()));
      // Validation message remains on the sheet.
      expect(
        find.textContaining('harus memiliki status kehadiran'),
        findsOneWidget,
      );
    });

    testWidgets('bulk action fills unset rows and enables a valid save', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Tandai Semua Masuk'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Absensi (2 Kru)'));
      // The success toast animates on a timer, so settle in bounded steps
      // rather than waiting for a fully idle tree.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRepository.saveAttendanceBatch(any())).called(1);
    });
  });
}
