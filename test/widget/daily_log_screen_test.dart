import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/core/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_form_sheet.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_list_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/auto_save_indicator.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/daily_log_card.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/hazard_assessment_field.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/weather_selector.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class MockDailyLogRepository extends Mock implements DailyLogRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(
      DailyLog(
        id: 'fallback-id',
        siteId: 'fallback-site',
        foremanId: 'fallback-foreman',
        logDate: DateTime.now(),
      ),
    );
  });

  late MockDailyLogRepository mockRepository;
  late MockZoneRepository mockZoneRepository;
  AuthCubit? testAuthCubit;

  // DailyLogListScreen resolves the viewer's role from the process-wide
  // `authCubit` global (production wiring). A supervisor session is installed
  // per-test where the supervisor-only approval path is exercised, and always
  // torn down so no test leaks a signed-in role into the next.
  void signInAsSupervisor() {
    testAuthCubit = AuthCubit(repository: MockAuthRepository())
      ..emit(
        const AuthState(
          status: AuthStatus.authenticated,
          user: UserEntity(
            id: 'SUPERVISOR-007',
            email: 'sup@mine.flow',
            name: 'Supervisor',
            role: 'supervisor',
            siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
          ),
        ),
      );
    authCubit = testAuthCubit;
  }

  tearDown(() async {
    authCubit = null;
    await testAuthCubit?.close();
    testAuthCubit = null;
  });

  final tDate = DateTime(2026, 7, 18);
  const tSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  const tForemanId = 'FOREMAN-001';

  final tLogs = [
    DailyLog(
      id: 'log-001',
      siteId: tSiteId,
      foremanId: tForemanId,
      logDate: tDate,
      zoneId: 'ZONE-PIT-A',
      status: LogStatus.draft,
      summary: 'Pemotongan lereng pit A utara selesai 500 m3.',
      weather: 'Cerah',
      hazard: const HazardAssessment.none(),
    ),
    DailyLog(
      id: 'log-002',
      siteId: tSiteId,
      foremanId: tForemanId,
      logDate: tDate.subtract(const Duration(days: 1)),
      zoneId: 'ZONE-SP-01',
      status: LogStatus.submitted,
      summary: 'Pemindahan OB ke stockpile 1 berjalan lancar.',
      weather: 'Berawan',
      hazard: const HazardAssessment(
        state: HazardState.present,
        severity: HazardSeverity.high,
        notes: 'Lereng tidak stabil',
        correctiveAction: 'Beri penahan',
      ),
    ),
  ];

  setUp(() {
    mockRepository = MockDailyLogRepository();
    mockZoneRepository = MockZoneRepository();

    when(
      () => mockRepository.getDailyLogs(
        date: any(named: 'date'),
        siteId: any(named: 'siteId'),
        foremanId: any(named: 'foremanId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => tLogs);

    when(() => mockRepository.getDailyLogById(any())).thenAnswer((
      invocation,
    ) async {
      final id = invocation.positionalArguments.first as String;
      return tLogs.where((l) => l.id == id).firstOrNull;
    });

    when(
      () => mockRepository.getDraftLogForForeman(
        foremanId: any(named: 'foremanId'),
        date: any(named: 'date'),
        siteId: any(named: 'siteId'),
      ),
    ).thenAnswer((_) async => tLogs.first);

    when(() => mockRepository.autoSaveDraft(any())).thenAnswer((_) async => {});
    when(
      () => mockRepository.submitDailyLog(any()),
    ).thenAnswer((_) async => {});
    when(
      () => mockRepository.approveDailyLog(
        any(),
        approvedBy: any(named: 'approvedBy'),
      ),
    ).thenAnswer((_) async => {});
    when(
      () => mockRepository.deleteDailyLog(any()),
    ).thenAnswer((_) async => {});
  });

  Widget wrap(Widget child) => FTheme(
    data: FTheme.neutral.light.touch,
    child: MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => FToaster(child: child!),
      home: child,
    ),
  );

  Widget buildFormSheetWidget({String? logId, DailyLog? existingLog}) {
    final sheet = DailyLogFormSheet(
      repository: mockRepository,
      zoneRepository: mockZoneRepository,
      foremanId: tForemanId,
      siteId: tSiteId,
      logId: logId,
      existingLog: existingLog,
      initialDate: tDate,
    );
    final router = GoRouter(
      initialLocation: '/teams/daily-log/form',
      routes: [
        GoRoute(
          path: '/teams/daily-log',
          builder: (_, _) => const Scaffold(body: Text('LIST')),
        ),
        GoRoute(path: '/teams/daily-log/form', builder: (_, _) => sheet),
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

  testWidgets('form sheet renders fields, hazard editor, weather selector', (
    tester,
  ) async {
    await tester.pumpWidget(buildFormSheetWidget());
    await tester.pumpAndSettle();

    expect(find.text('Log Operasional Harian'), findsOneWidget);
    expect(find.byType(AutoSaveIndicator), findsOneWidget);
    expect(find.byType(ZonePicker), findsOneWidget);
    expect(find.byType(WeatherSelector), findsOneWidget);
    expect(find.byType(HazardAssessmentField), findsOneWidget);
    expect(find.byKey(const Key('submit_daily_log_button')), findsOneWidget);
  });

  testWidgets('validation error when submitting with empty summary', (
    tester,
  ) async {
    final emptyDraft = DailyLog(
      id: 'log-empty',
      siteId: tSiteId,
      foremanId: tForemanId,
      logDate: tDate,
      status: LogStatus.draft,
      summary: '',
      hazard: const HazardAssessment.none(),
    );

    await tester.pumpWidget(buildFormSheetWidget(existingLog: emptyDraft));
    await tester.pumpAndSettle();

    final submitBtn = find.byKey(const Key('submit_daily_log_button'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan pekerjaan harian wajib diisi'), findsOneWidget);
    verifyNever(() => mockRepository.submitDailyLog(any()));
  });

  testWidgets(
    'hazard question must be answered before submit (not_assessed blocks)',
    (tester) async {
      // Summary present but hazard never answered.
      final unanswered = DailyLog(
        id: 'log-unanswered',
        siteId: tSiteId,
        foremanId: tForemanId,
        logDate: tDate,
        status: LogStatus.draft,
        summary: 'Pekerjaan berjalan lancar.',
        hazard: const HazardAssessment.notAssessed(),
      );

      await tester.pumpWidget(buildFormSheetWidget(existingLog: unanswered));
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('submit_daily_log_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Assessment bahaya wajib diisi sebelum mengirim log'),
        findsOneWidget,
      );
      verifyNever(() => mockRepository.submitDailyLog(any()));
    },
  );

  testWidgets(
    'present hazard without severity blocks submit; selecting severity unblocks',
    (tester) async {
      final presentNoSeverity = DailyLog(
        id: 'log-hazard',
        siteId: tSiteId,
        foremanId: tForemanId,
        logDate: tDate,
        status: LogStatus.draft,
        summary: 'Pekerjaan berjalan lancar.',
        hazard: const HazardAssessment(state: HazardState.present),
      );

      await tester.pumpWidget(
        buildFormSheetWidget(existingLog: presentNoSeverity),
      );
      await tester.pumpAndSettle();

      // Severity buttons are visible because state = present.
      expect(find.text('Tingkat Keparahan *'), findsOneWidget);

      final submitBtn = find.byKey(const Key('submit_daily_log_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Pilih tingkat keparahan bahaya'), findsOneWidget);
      verifyNever(() => mockRepository.submitDailyLog(any()));

      // Answer the severity, then submit succeeds.
      await tester.ensureVisible(find.byKey(const Key('hazard_severity_high')));
      await tester.tap(find.byKey(const Key('hazard_severity_high')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      verify(() => mockRepository.submitDailyLog('log-hazard')).called(1);
      await tester.pump(const Duration(milliseconds: 700));
    },
  );

  testWidgets('submit calls repository with hazard preserved', (tester) async {
    await tester.pumpWidget(buildFormSheetWidget());
    await tester.pumpAndSettle();

    final submitBtn = find.byKey(const Key('submit_daily_log_button'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    verify(() => mockRepository.submitDailyLog('log-001')).called(1);
    final savedLog =
        verify(() => mockRepository.autoSaveDraft(captureAny())).captured.last
            as DailyLog;
    expect(savedLog.hazard.state, HazardState.none);
    expect(find.text('Log harian berhasil dikirim!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('weather selection triggers auto-save (single-select)', (
    tester,
  ) async {
    await tester.pumpWidget(buildFormSheetWidget());
    await tester.pumpAndSettle();

    final weatherBtn = find.byKey(const Key('weather_option_Hujan Ringan'));
    expect(weatherBtn, findsOneWidget);
    await tester.ensureVisible(weatherBtn);
    await tester.tap(weatherBtn);
    await tester.pumpAndSettle();

    verify(
      () => mockRepository.autoSaveDraft(any()),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets(
    'record route fetches by ID and renders read-only for submitted',
    (tester) async {
      await tester.pumpWidget(buildFormSheetWidget(logId: 'log-002'));
      await tester.pumpAndSettle();

      // Fetched by ID (durable identity, not extra).
      verify(() => mockRepository.getDailyLogById('log-002')).called(1);
      // Read-only surface for a submitted log.
      expect(find.text('Log Operasional Harian'), findsOneWidget);
      expect(find.byKey(const Key('submit_daily_log_button')), findsNothing);
      expect(find.byType(HazardAssessmentField), findsNothing);
      // Hazard summary visible (present + severity high).
      expect(find.textContaining('high'), findsOneWidget);
    },
  );

  testWidgets(
    'list screen renders role-aware tabs with counts and review cards',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          DailyLogListScreen(
            repository: mockRepository,
            zoneRepository: mockZoneRepository,
            foremanId: tForemanId,
            siteId: tSiteId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Log Harian'), findsOneWidget);
      // Tab strip labels (with counts derived from the load).
      expect(find.text('Semua (2)'), findsOneWidget);
      expect(find.text('Draft (1)'), findsOneWidget);
      expect(find.text('Perlu Disetujui (1)'), findsOneWidget);
      expect(find.text('Disetujui (0)'), findsOneWidget);

      // Default tab for a foreman (no supervisor auth): Draft.
      expect(find.byType(DailyLogCard), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      // No supervisor approval control for a foreman viewer.
      expect(find.byKey(const Key('approve_daily_log_button')), findsNothing);
    },
  );

  testWidgets('switching tabs filters visible cards without reload flash', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        DailyLogListScreen(
          repository: mockRepository,
          zoneRepository: mockZoneRepository,
          foremanId: tForemanId,
          siteId: tSiteId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Perlu Disetujui (1)'));
    await tester.tap(find.text('Perlu Disetujui (1)'));
    await tester.pumpAndSettle();

    expect(find.byType(DailyLogCard), findsOneWidget);
    expect(find.text('PERLU DISETUJUI'), findsOneWidget);
    // No blank loading screen between tab switches.
    expect(find.byType(FCircularProgress), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // STEP-55.6 RESIDUAL (2026-09-21): supervisor approval path — the confirm
  // dialog is ForUI (spec §4.5 item 9 / FC-54.6-009, no Material AlertDialog),
  // approval is supervisor-only (FC-54.6-004), and confirm dispatches with the
  // authenticated supervisor id (never a URL-supplied id / FC-54.6-011).
  // ---------------------------------------------------------------------------

  testWidgets(
    'supervisor sees the approval control on a submitted log; foreman does not',
    (tester) async {
      signInAsSupervisor();
      await tester.pumpWidget(
        wrap(
          DailyLogListScreen(
            repository: mockRepository,
            zoneRepository: mockZoneRepository,
            foremanId: null, // supervisor sees the site-wide queue
            siteId: tSiteId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Supervisor default tab is "Perlu Disetujui" (submitted queue).
      expect(find.text('PERLU DISETUJUI'), findsOneWidget);
      expect(find.byKey(const Key('approve_daily_log_button')), findsOneWidget);
    },
  );

  testWidgets(
    'approval confirm dialog is ForUI (FDialog/FAlert), not Material AlertDialog',
    (tester) async {
      signInAsSupervisor();
      await tester.pumpWidget(
        wrap(
          DailyLogListScreen(
            repository: mockRepository,
            zoneRepository: mockZoneRepository,
            foremanId: null,
            siteId: tSiteId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final approveBtn = find.byKey(const Key('approve_daily_log_button'));
      await tester.ensureVisible(approveBtn);
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      // ForUI dialog surface, no Material AlertDialog anywhere in the tree.
      expect(find.byType(FDialog), findsOneWidget);
      expect(find.byType(FAlert), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      // Named-record confirmation copy preserved (date + foreman).
      expect(find.textContaining('Setujui log'), findsOneWidget);
      expect(find.text('Setujui'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    },
  );

  testWidgets(
    'confirming approval dispatches with the authenticated supervisor id',
    (tester) async {
      signInAsSupervisor();
      await tester.pumpWidget(
        wrap(
          DailyLogListScreen(
            repository: mockRepository,
            zoneRepository: mockZoneRepository,
            foremanId: null,
            siteId: tSiteId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('approve_daily_log_button')),
      );
      await tester.tap(find.byKey(const Key('approve_daily_log_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Setujui'));
      await tester.pumpAndSettle();

      // log-002 is the submitted record; approvedBy is the signed-in supervisor,
      // not any id sourced from the route.
      verify(
        () => mockRepository.approveDailyLog(
          'log-002',
          approvedBy: 'SUPERVISOR-007',
        ),
      ).called(1);
    },
  );

  testWidgets('cancelling the approval dialog dispatches nothing', (
    tester,
  ) async {
    signInAsSupervisor();
    await tester.pumpWidget(
      wrap(
        DailyLogListScreen(
          repository: mockRepository,
          zoneRepository: mockZoneRepository,
          foremanId: null,
          siteId: tSiteId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('approve_daily_log_button')),
    );
    await tester.tap(find.byKey(const Key('approve_daily_log_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.byType(FDialog), findsNothing);
    verifyNever(
      () => mockRepository.approveDailyLog(
        any(),
        approvedBy: any(named: 'approvedBy'),
      ),
    );
  });
}
