import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late AuthCubit testAuthCubit;

  const tSiteId = 'site-pit-01';
  const tForemanId = 'foreman-agus';

  AuthState supervisorState() => const AuthState(
    status: AuthStatus.authenticated,
    user: UserEntity(
      id: 'sup-1',
      email: 'sup@mine.flow',
      name: 'Supervisor',
      role: 'supervisor',
      siteId: tSiteId,
    ),
  );

  AuthState foremanState() => const AuthState(
    status: AuthStatus.authenticated,
    user: UserEntity(
      id: 'foreman-agus',
      email: 'agus@mine.flow',
      name: 'Agus Foreman',
      role: 'foreman',
      siteId: tSiteId,
    ),
  );

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
    // STEP-55.7 RESIDUAL (2026-09-21): the process-wide authCubit global is
    // intentionally left unset. The session under test is provided through
    // the widget tree in buildTestWidget — the production wiring — so the
    // role-gating tests assert the screen's own session resolution.
    final mockAuthRepo = MockAuthRepository();
    testAuthCubit = AuthCubit(repository: mockAuthRepo);
    testAuthCubit.emit(supervisorState());

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

  tearDown(() async {
    await testAuthCubit.close();
  });

  Widget buildTestWidget({
    required String checkId,
    EquipmentCheck? existingCheck,
    VoidCallback? onClose,
    bool Function(String siteId)? siteAuthorizationGuard,
    Size surfaceSize = const Size(400, 800),
    AuthState Function()? sessionState,
    FThemeData? theme,
  }) {
    final state = sessionState != null ? sessionState() : testAuthCubit.state;
    return MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: surfaceSize),
        child: FTheme(
          data: theme ?? FTheme.neutral.light.touch,
          child: FToaster(child: child!),
        ),
      ),
      home: BlocProvider<AuthCubit>.value(
        value: testAuthCubit..emit(state),
        child: EquipmentCheckDetailScreen(
          repository: mockRepository,
          checkId: checkId,
          existingCheck: existingCheck,
          onClose: onClose,
          siteAuthorizationGuard: siteAuthorizationGuard,
        ),
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
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
            sessionState: foremanState,
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

    // STEP-55.7 RESIDUAL (2026-09-21): FC-54.7-007 runtime audit stays
    // Unverified (55.11 deferral). Mechanical coverage only — no runtime
    // verification is claimed.
    testWidgets(
      'mechanical: PASS/FAIL badges carry dual icon+text semantics (FC-54.7-002, 004, 007)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        // Text labels present for both verdicts (never color-only).
        expect(find.text('PASS'), findsWidgets);
        expect(find.text('FAIL'), findsWidgets);
        // Dual icons present alongside the text.
        expect(find.byIcon(LucideIcons.checkCircle2), findsWidgets);
        expect(find.byIcon(LucideIcons.xCircle), findsWidgets);
        // Every verdict badge exposes an accessible semantics label.
        final badges = tester.widgetList<AppStatusBadge>(
          find.byType(AppStatusBadge),
        );
        expect(badges, isNotEmpty);
        for (final badge in badges) {
          expect(badge.label.trim(), isNotEmpty);
        }
      },
    );

    testWidgets(
      'mechanical: long SOP checklist preserves reading order with per-item semantics (FC-54.7-007)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        // 16 SOP items (spec long-list band 15–30) render in order.
        for (var i = 0; i < 16; i++) {
          expect(
            find.text('Pemeriksaan Komponen SOP #${i + 1}'),
            findsOneWidget,
          );
        }
        final first = tester.getTopLeft(
          find.text('Pemeriksaan Komponen SOP #1'),
        );
        final last = tester.getTopLeft(
          find.text('Pemeriksaan Komponen SOP #16'),
        );
        expect(first.dy, lessThan(last.dy));
        // Defect remarks surface inline with their failed items.
        expect(find.textContaining('Ditemukan retak'), findsWidgets);
      },
    );

    testWidgets(
      'mechanical: 48dp minimum on the destructive footer action (FC-54.7-007)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        // The sheet wraps every footer in ConstrainedBox(minHeight: 48);
        // the supervisor-only delete FButton must sit inside that wrapper.
        final deleteButton = find.widgetWithText(FButton, 'Hapus Catatan');
        expect(deleteButton, findsOneWidget);
        final wrapper = find.ancestor(
          of: deleteButton,
          matching: find.byWidgetPredicate(
            (w) => w is ConstrainedBox && w.constraints.minHeight == 48,
          ),
        );
        expect(wrapper, findsWidgets);
      },
    );

    testWidgets(
      'mechanical: single scroll owner in the detail sheet (FC-54.7-007)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        final sheet = find.byType(AppResponsiveSheet);
        expect(sheet, findsOneWidget);
        // Exactly one primary scroll view owns the sheet body — no nested
        // competing scrollers around the long checklist.
        final primaries = find.descendant(
          of: sheet,
          matching: find.byWidgetPredicate(
            (w) =>
                w is SingleChildScrollView ||
                (w is ListView && w.primary == true),
          ),
        );
        expect(primaries, findsOneWidget);
      },
    );

    // NOTE: one pump per test below — re-pumping the same tree with a
    // different checkId reuses the mounted EquipmentCheckBloc without a new
    // load event, so the second pump would assert against stale state.
    testWidgets(
      'mechanical: not-found panel renders with recovery action (FC-54.7-001)',
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
      'mechanical: access-denied panel renders with recovery action (FC-54.7-003)',
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
        expect(find.text('Kembali'), findsOneWidget);
      },
    );

    testWidgets(
      'mechanical: 2.0x text scale renders the detail without overflow (FC-54.7-007)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Detail Pemeriksaan Peralatan'), findsWidgets);
      },
    );

    testWidgets(
      'mechanical: dark mode renders the detail cleanly without errors (FC-54.7-007)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestWidget(
            checkId: 'check-sop-101',
            surfaceSize: const Size(400, 800),
            theme: FTheme.neutral.dark.touch,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Detail Pemeriksaan Peralatan'), findsWidgets);
      },
    );
  });
}
