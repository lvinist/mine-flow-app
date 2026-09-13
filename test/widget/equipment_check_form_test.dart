import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/core/domain/entities/user_entity.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_check_form_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/condition_summary_badge.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_type_tabs.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/sop_checklist_item_card.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class MockEquipmentCheckRepository extends Mock
    implements EquipmentCheckRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeEquipmentCheck extends Fake implements EquipmentCheck {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    registerFallbackValue(FakeEquipmentCheck());
  });

  late MockEquipmentCheckRepository mockRepository;

  const tSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
  const tForemanId = 'foreman-001';

  setUp(() {
    mockRepository = MockEquipmentCheckRepository();
    when(
      () => mockRepository.saveEquipmentCheck(any()),
    ).thenAnswer((_) async => {});
  });

  tearDown(() {
    authCubit = null;
  });

  Widget buildTestWidget({
    String siteId = tSiteId,
    String foremanId = tForemanId,
    bool Function(String)? siteAuthorizationGuard,
    VoidCallback? onClose,
  }) {
    return MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => FTheme(
        data: FTheme.neutral.light.touch,
        child: FToaster(child: child!),
      ),
      home: EquipmentCheckFormScreen(
        repository: mockRepository,
        siteId: siteId,
        foremanId: foremanId,
        siteAuthorizationGuard: siteAuthorizationGuard,
        onClose: onClose,
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
        // CF-017: a fresh form is unanswered, so it is NOT "PASSED".
        expect(find.text('PERLU MAINTENANCE / FLAGGED'), findsOneWidget);
        expect(find.text('0 dari 5 Item SOP Lolos Check'), findsOneWidget);

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
      'should mark an item FAIL and show the required damage note field',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Fresh form is unanswered → not PASSED.
        expect(find.text('PERLU MAINTENANCE / FLAGGED'), findsOneWidget);

        // Find the first FAIL button
        final failButtons = find.text('FAIL');
        expect(failButtons, findsNWidgets(5));

        await tester.ensureVisible(failButtons.first);
        await tester.tap(failButtons.first);
        await tester.pumpAndSettle();

        expect(find.text('PERLU MAINTENANCE / FLAGGED'), findsOneWidget);
        expect(find.text('0 dari 5 Item SOP Lolos Check'), findsOneWidget);

        final requiredNoteField = find.text(
          'Catatan Kerusakan / Kendala (Wajib)',
        );
        await tester.ensureVisible(requiredNoteField);
        expect(requiredNoteField, findsOneWidget);
      },
    );

    testWidgets('should save equipment check when submit button is pressed', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final serialNumberField = find
          .descendant(
            of: find.byType(FTextField),
            matching: find.byType(EditableText),
          )
          .first;
      expect(serialNumberField, findsOneWidget);

      await tester.enterText(serialNumberField, 'GNSS-TEST-99');
      await tester.pumpAndSettle();

      // CF-017: answer all 5 SOP items PASS before submit becomes enabled.
      for (var i = 0; i < 5; i++) {
        final passFinder = find.text('PASS').at(i);
        await tester.ensureVisible(passFinder);
        await tester.tap(passFinder);
        await tester.pump();
      }
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

    testWidgets(
      'should show access denied panel when site context is unauthorized (FC-54.7-003)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            siteId: 'unauthorized-site-999',
            siteAuthorizationGuard: (siteId) => false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Akses Ditolak'), findsOneWidget);
        expect(
          find.text('Lokasi kerja tidak valid atau Anda tidak memiliki akses.'),
          findsOneWidget,
        );
        expect(find.text('Kembali ke daftar'), findsOneWidget);
      },
    );

    testWidgets(
      'switching equipment tabs after entering damage note on item does not auto-fail new tab items',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // 1. On GNSS, mark first item FAIL and type damage note
        final failButtons = find.text('FAIL');
        await tester.ensureVisible(failButtons.first);
        await tester.tap(failButtons.first);
        await tester.pumpAndSettle();

        final noteField = find.byType(FTextField).last;
        await tester.enterText(noteField, 'Retak pada casing antena');
        await tester.pumpAndSettle();

        // 2. Switch to Total Station tab
        final totalStationTab = find.text('Total Station');
        await tester.ensureVisible(totalStationTab);
        await tester.tap(totalStationTab);
        await tester.pumpAndSettle();

        // 3. Total Station items must remain un-answered (no damage note field shown)
        expect(find.text('Levelling Nivo & Optical Plummet'), findsOneWidget);
        expect(find.text('Catatan Kerusakan / Kendala (Wajib)'), findsNothing);
      },
    );

    testWidgets(
      'should derive foreman identity from authenticated session when foremanId is not passed (FC-54.7-003)',
      (tester) async {
        final mockAuthRepo = MockAuthRepository();
        authCubit = AuthCubit(repository: mockAuthRepo);
        authCubit!.emit(
          const AuthState(
            status: AuthStatus.authenticated,
            user: UserEntity(
              id: 'session-foreman-42',
              email: 'foreman42@mine.flow',
              name: 'Foreman 42',
              role: 'foreman',
              siteId: tSiteId,
            ),
          ),
        );

        await tester.pumpWidget(
          buildTestWidget(
            foremanId: '', // Empty parameter -> derived from session
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Inspeksi SOP Peralatan'), findsOneWidget);
        expect(find.byType(EquipmentTypeTabs), findsOneWidget);

        // Enter serial and answers, then submit
        final serialNumberField = find
            .descendant(
              of: find.byType(FTextField),
              matching: find.byType(EditableText),
            )
            .first;
        await tester.enterText(serialNumberField, 'GNSS-FOREMAN-42');
        await tester.pumpAndSettle();

        for (var i = 0; i < 5; i++) {
          final passFinder = find.text('PASS').at(i);
          await tester.ensureVisible(passFinder);
          await tester.tap(passFinder);
          await tester.pump();
        }
        await tester.pumpAndSettle();

        final submitButton = find.widgetWithText(
          FButton,
          'Simpan Inspeksi SOP (5/5 Lolos)',
        );
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        verify(
          () => mockRepository.saveEquipmentCheck(
            any(
              that: predicate<EquipmentCheck>(
                (c) => c.foremanId == 'session-foreman-42',
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'should trigger dirty dismissal dialog when closing sheet with unsaved input (D4 dirty guard)',
      (tester) async {
        bool closed = false;
        await tester.pumpWidget(buildTestWidget(onClose: () => closed = true));
        await tester.pumpAndSettle();

        // Enter serial number to make form dirty
        final serialNumberField = find
            .descendant(
              of: find.byType(FTextField),
              matching: find.byType(EditableText),
            )
            .first;
        await tester.enterText(serialNumberField, 'UNSAVED-SERIAL');
        await tester.pumpAndSettle();

        // Tap barrier or close button to trigger dismissal
        final closeButton = find.byType(AppAccessibleIconButton);
        expect(closeButton, findsOneWidget);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Dirty dismiss dialog should appear
        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);
        expect(find.text('Perubahan belum disimpan'), findsOneWidget);
        expect(
          find.text('Perubahan yang belum disimpan akan hilang.'),
          findsOneWidget,
        );

        // Discard changes
        final discardButton = find.text('Buang Perubahan');
        expect(discardButton, findsOneWidget);
        await tester.tap(discardButton);
        await tester.pumpAndSettle();

        expect(closed, isTrue);
      },
    );
  });
}
