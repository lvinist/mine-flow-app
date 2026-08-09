import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_form_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_list_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/auto_save_indicator.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/daily_log_card.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/weather_selector.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';

class MockDailyLogRepository extends Mock implements DailyLogRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

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

  final tDate = DateTime(2026, 7, 18);
  const tSiteId = '00000000-0000-0000-0000-000000000001';
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
      () => mockRepository.deleteDailyLog(any()),
    ).thenAnswer((_) async => {});
  });

  Widget buildFormScreenWidget({DailyLog? existingLog}) {
    return MaterialApp(
      builder: (context, child) => FTheme(
        data: FTheme.neutral.light.touch,
        child: child!,
      ),
      home: DailyLogFormScreen(
        repository: mockRepository,
        zoneRepository: mockZoneRepository,
        foremanId: tForemanId,
        siteId: tSiteId,
        initialDate: tDate,
        existingLog: existingLog,
      ),
    );
  }

  Widget buildListScreenWidget() {
    return MaterialApp(
      builder: (context, child) => FTheme(
        data: FTheme.neutral.light.touch,
        child: child!,
      ),
      home: DailyLogListScreen(
        repository: mockRepository,
        zoneRepository: mockZoneRepository,
        foremanId: tForemanId,
        siteId: tSiteId,
      ),
    );
  }

  group('DailyLogFormScreen Widget Tests', () {
    testWidgets(
      'should render all form fields, weather selector, and auto save indicator',
      (tester) async {
        await tester.pumpWidget(buildFormScreenWidget());
        await tester.pumpAndSettle();

        expect(find.text('Log Operasional Harian'), findsOneWidget);
        expect(find.byType(AutoSaveIndicator), findsOneWidget);
        expect(find.byType(ZonePicker), findsOneWidget);
        expect(find.byType(WeatherSelector), findsOneWidget);
        expect(find.text('Ringkasan Pekerjaan *'), findsOneWidget);
        expect(find.text('Catatan Tambahan & K3 (Safety)'), findsOneWidget);
        expect(
          find.byKey(const Key('submit_daily_log_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should show validation error when submitting with empty summary',
      (tester) async {
        final emptyDraft = DailyLog(
          id: 'log-empty',
          siteId: tSiteId,
          foremanId: tForemanId,
          logDate: tDate,
          status: LogStatus.draft,
          summary: '',
        );

        await tester.pumpWidget(buildFormScreenWidget(existingLog: emptyDraft));
        await tester.pumpAndSettle();

        final submitBtn = find.byKey(const Key('submit_daily_log_button'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Ringkasan pekerjaan harian wajib diisi'),
          findsOneWidget,
        );
        verifyNever(() => mockRepository.submitDailyLog(any()));
      },
    );

    testWidgets(
      'should call submitDailyLog when form is valid and submit button pressed',
      (tester) async {
        await tester.pumpWidget(buildFormScreenWidget());
        await tester.pumpAndSettle();

        final submitBtn = find.byKey(const Key('submit_daily_log_button'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        verify(() => mockRepository.submitDailyLog('log-001')).called(1);
        expect(find.text('Log harian berhasil dikirim!'), findsOneWidget);
      },
    );

    testWidgets('should select weather chip and trigger auto-save', (
      tester,
    ) async {
      await tester.pumpWidget(buildFormScreenWidget());
      await tester.pumpAndSettle();

      final weatherChip = find.text('Hujan Ringan');
      expect(weatherChip, findsOneWidget);

      await tester.tap(weatherChip);
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.autoSaveDraft(any()),
      ).called(greaterThanOrEqualTo(1));
    });
  });

  group('DailyLogListScreen Widget Tests', () {
    testWidgets(
      'should render list screen title, filter chips, and daily log cards',
      (tester) async {
        await tester.pumpWidget(buildListScreenWidget());
        await tester.pumpAndSettle();

        expect(find.text('Riwayat Log Harian'), findsOneWidget);
        expect(find.text('Semua Status'), findsOneWidget);
        expect(find.text('Draft'), findsWidgets);
        expect(find.text('Terkirim'), findsWidgets);

        expect(find.byType(DailyLogCard), findsNWidgets(2));
        expect(find.text('DRAFT'), findsOneWidget);
        expect(find.text('TERKIRIM'), findsOneWidget);
      },
    );

    testWidgets('should filter logs list when status filter chip is clicked', (
      tester,
    ) async {
      await tester.pumpWidget(buildListScreenWidget());
      await tester.pumpAndSettle();

      final draftChipFilter = find.widgetWithText(FilterChip, 'Draft');
      await tester.tap(draftChipFilter);
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.getDailyLogs(
          date: any(named: 'date'),
          siteId: tSiteId,
          foremanId: tForemanId,
          status: LogStatus.draft,
        ),
      ).called(1);
    });
  });
}
