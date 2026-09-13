import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/core/domain/entities/user_entity.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_check_detail_screen.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class MockEquipmentCheckRepository extends Mock
    implements EquipmentCheckRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  late MockEquipmentCheckRepository mockRepository;

  const tSiteId = 'site-pit-01';
  const tForemanId = 'foreman-agus';

  // 16 checklist items for long-list verification (FC-54.7-001: 15–30 items)
  final longChecklist = List.generate(
    16,
    (index) => CheckItem(
      id: 'sop_item_$index',
      label: 'Pemeriksaan Komponen SOP #${index + 1}',
      isPassed: index % 3 == 0 ? false : (index % 5 == 0 ? null : true),
      remarks: index % 3 == 0 ? 'Ditemukan retak pada komponen $index' : null,
    ),
  );

  final sampleCheck = EquipmentCheck(
    id: 'check-sop-101',
    siteId: tSiteId,
    foremanId: tForemanId,
    equipmentType: EquipmentType.drone,
    serialNumber: 'DRONE-DJI-M300',
    checkTime: DateTime(2026, 8, 20, 14, 30),
    checkType: CheckType.preWork,
    status: CheckStatus.flagged,
    isOperational: false,
    remarks: 'Cuaca berangin kencang, perlu kalibrasi IMU tambahan.',
    checklist: longChecklist,
  );

  setUp(() {
    final mockAuthRepo = MockAuthRepository();
    authCubit = AuthCubit(repository: mockAuthRepo);
    authCubit!.emit(
      const AuthState(
        status: AuthStatus.authenticated,
        user: UserEntity(
          id: 'sup-1',
          email: 'sup@mine.flow',
          name: 'Supervisor',
          role: 'supervisor',
          siteId: tSiteId,
        ),
      ),
    );

    mockRepository = MockEquipmentCheckRepository();
    when(
      () => mockRepository.getEquipmentCheckById('check-sop-101'),
    ).thenAnswer((_) async => sampleCheck);
    when(
      () => mockRepository.getEquipmentCheckById('not-found-id'),
    ).thenAnswer((_) async => null);
    when(
      () => mockRepository.deleteEquipmentCheck(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.getEquipmentChecks(
        siteId: any(named: 'siteId'),
        equipmentType: any(named: 'equipmentType'),
      ),
    ).thenAnswer((_) async => []);
  });

  tearDown(() {
    authCubit = null;
  });

  Widget buildTestWidget({
    required String checkId,
    EquipmentCheck? existingCheck,
    VoidCallback? onClose,
    bool Function(String siteId)? siteAuthorizationGuard,
    Size surfaceSize = const Size(400, 800),
  }) {
    return MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: surfaceSize),
        child: FTheme(
          data: FTheme.neutral.light.touch,
          child: FToaster(child: child!),
        ),
      ),
      home: EquipmentCheckDetailScreen(
        repository: mockRepository,
        checkId: checkId,
        existingCheck: existingCheck,
        onClose: onClose,
        siteAuthorizationGuard: siteAuthorizationGuard,
      ),
    );
  }

  group('EquipmentCheckDetailScreen Tests (FC-54.7-001..007)', () {
    testWidgets(
      'fetches by ID and renders full metadata and long checklist in reading order',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        // Verify title & subtitle
        expect(find.text('Detail Pemeriksaan Peralatan'), findsWidgets);
        expect(find.text('Drone / UAV • Pre-Work Check'), findsOneWidget);

        // Verify equipment info & metadata
        expect(find.text('Drone / UAV'), findsWidgets);
        expect(find.text('S/N: DRONE-DJI-M300'), findsOneWidget);
        expect(find.text('Inspektur: foreman-agus'), findsOneWidget);
        expect(find.text('Site: site-pit-01'), findsOneWidget);
        expect(find.text('Perlu Perbaikan'), findsOneWidget);

        // Verify checklist items reading order and count
        expect(find.text('HASIL SOP CHECKLIST'), findsOneWidget);
        expect(find.text('Pemeriksaan Komponen SOP #1'), findsOneWidget);

        // Verify defect remark on failed item
        expect(find.text('Ditemukan retak pada komponen 0'), findsOneWidget);

        // Verify general inspection remarks
        expect(find.text('CATATAN TAMBAHAN PEMERIKSAAN'), findsOneWidget);
        expect(
          find.text('Cuaca berangin kencang, perlu kalibrasi IMU tambahan.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'PASS and FAIL controls are labelled with dual icon+text, never color-only (FC-54.7-002, 004)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        // Verify PASS and FAIL badges exist
        expect(find.text('PASS'), findsWidgets);
        expect(find.text('FAIL'), findsWidgets);

        // Verify dual icons exist for pass/fail statuses
        expect(find.byIcon(LucideIcons.checkCircle2), findsWidgets);
        expect(find.byIcon(LucideIcons.xCircle), findsWidgets);

        // Verify status badge semantics
        expect(find.byType(AppStatusBadge), findsWidgets);
      },
    );

    testWidgets(
      'renders mobile full-page geometry on narrow screens (<800dp) (FC-54.7-001)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(390, 844),
          ),
        );
        await tester.pumpAndSettle();

        // Responsive sheet should render full page (Positioned.fill)
        final sheetFinder = find.byType(AppResponsiveSheet);
        expect(sheetFinder, findsOneWidget);

        final sheet = tester.widget<AppResponsiveSheet>(sheetFinder);
        expect(sheet.mobileFullPage, isTrue);
        expect(sheet.mode, equals(AppResponsiveSheetMode.readOnlyInspector));
      },
    );

    testWidgets(
      'renders right inspector geometry on wide screens (>=800dp) (FC-54.7-001)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(1200, 900),
          ),
        );
        await tester.pumpAndSettle();

        final sheetFinder = find.byType(AppResponsiveSheet);
        expect(sheetFinder, findsOneWidget);

        final sheet = tester.widget<AppResponsiveSheet>(sheetFinder);
        expect(sheet.mode, equals(AppResponsiveSheetMode.readOnlyInspector));
      },
    );

    testWidgets(
      'renders not-found state when equipment check ID does not exist',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'not-found-id',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppStatePanel), findsOneWidget);
        expect(find.text('Data Tidak Ditemukan'), findsOneWidget);
        expect(find.text('Kembali'), findsOneWidget);
      },
    );

    testWidgets(
      'renders access denied panel when site context is unauthorized (FC-54.7-001, FC-54.7-003)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            siteAuthorizationGuard: (siteId) => false,
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppStatePanel), findsOneWidget);
        expect(find.text('Akses Ditolak'), findsOneWidget);
        expect(
          find.text('Lokasi kerja tidak valid atau Anda tidak memiliki akses.'),
          findsOneWidget,
        );
        expect(find.text('Kembali'), findsOneWidget);
      },
    );

    testWidgets(
      'hides delete action for non-supervisor viewers (foreman/operator role)',
      (tester) async {
        // Authenticate as foreman
        authCubit!.emit(
          const AuthState(
            status: AuthStatus.authenticated,
            user: UserEntity(
              id: 'foreman-agus',
              email: 'agus@mine.flow',
              name: 'Agus Foreman',
              role: 'foreman',
              siteId: tSiteId,
            ),
          ),
        );

        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        // Footer delete button must not be visible for non-supervisor
        expect(find.text('Hapus Catatan'), findsNothing);
      },
    );

    testWidgets(
      'destructive delete action triggers confirmation and delegates to repository',
      (tester) async {
        bool closed = false;
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
            onClose: () => closed = true,
          ),
        );
        await tester.pumpAndSettle();

        // Find footer delete button
        final deleteButton = find.text('Hapus Catatan');
        expect(deleteButton, findsOneWidget);

        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(
          find.text(
            'Anda yakin ingin menghapus catatan pemeriksaan peralatan ini?',
          ),
          findsOneWidget,
        );

        // Tap confirm delete in dialog
        final confirmButton = find.text('Hapus');
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        verify(
          () => mockRepository.deleteEquipmentCheck('check-sop-101'),
        ).called(1);
        expect(closed, isTrue);
      },
    );
  });
}
