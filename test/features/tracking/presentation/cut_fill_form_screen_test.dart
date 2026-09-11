import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_form_screen.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockTrackingRepository mockTrackingRepository;
  late MockZoneRepository mockZoneRepository;

  final testRecord = CutFillRecord(
    id: 'cf-test-1',
    siteId: 'site-1',
    zoneId: 'zone-1',
    bcmVolume: 120.0,
    lcmVolume: 80.0,
    materialType: 'OB / Waste',
    elevationChange: -2.5,
    measurementDate: DateTime(2026, 3, 15),
    notes: 'Existing test note',
  );

  final testZones = [
    const ZoneEntity(id: 'zone-1', name: 'Pit A', siteId: 'site-1'),
    const ZoneEntity(id: 'zone-2', name: 'Pit B', siteId: 'site-1'),
  ];

  setUpAll(() async {
    registerFallbackValue(testRecord);
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    mockTrackingRepository = MockTrackingRepository();
    mockZoneRepository = MockZoneRepository();
    when(() => mockZoneRepository.getZones()).thenReturn(testZones);
  });

  Widget createWidgetUnderTest({
    String? recordId,
    CutFillRecord? existingRecord,
    String? initialZoneId,
    Uri? routeUri,
    VoidCallback? onClose,
    Size size = const Size(1024, 768),
  }) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FToaster(child: child!),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: CutFillFormScreen(
              repository: mockTrackingRepository,
              zoneRepository: mockZoneRepository,
              siteId: 'site-1',
              foremanId: 'foreman-1',
              recordId: recordId,
              existingRecord: existingRecord,
              initialZoneId: initialZoneId,
              routeUri: routeUri,
              onClose: onClose,
            ),
          ),
        ),
      ),
    );
  }

  group('CutFillFormScreen', () {
    testWidgets(
      'renders Volume (BCM) and Volume (LCM) labels and no stepper buttons (CF-014)',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Volume (BCM)'), findsOneWidget);
        expect(find.text('Volume (LCM)'), findsOneWidget);
        expect(find.byType(ZonePicker), findsOneWidget);
        expect(find.byIcon(LucideIcons.minus), findsNothing);
        expect(find.byIcon(LucideIcons.plus), findsNothing);
      },
    );

    testWidgets('renders create form elements properly for new measurement', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Pengukuran Baru'), findsOneWidget);
      expect(find.text('Tanggal Pengukuran'), findsOneWidget);
      expect(find.text('Perubahan Elevasi (opsional)'), findsOneWidget);
      expect(find.text('Tipe Material'), findsOneWidget);
      expect(find.text('Volume Setara Bank'), findsOneWidget);
      expect(find.text('Catatan'), findsOneWidget);
      expect(find.byKey(const Key('save_cut_fill_button')), findsOneWidget);
    });

    testWidgets(
      'clean dismissal closes form without dirty confirmation dialog',
      (tester) async {
        bool closed = false;
        await tester.pumpWidget(
          createWidgetUnderTest(onClose: () => closed = true),
        );
        await tester.pumpAndSettle();

        final closeButton = find.byIcon(Icons.close);
        expect(closeButton, findsOneWidget);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        expect(closed, isTrue);
        expect(find.byType(AppDirtyDismissDialog), findsNothing);
      },
    );

    testWidgets(
      'dirty dismissal triggers AppDirtyDismissDialog and handles continue vs discard',
      (tester) async {
        bool closed = false;
        await tester.pumpWidget(
          createWidgetUnderTest(onClose: () => closed = true),
        );
        await tester.pumpAndSettle();

        // Mutate form state by entering BCM volume
        final bcmInput = find.byType(TextField).first;
        await tester.enterText(bcmInput, '150');
        await tester.pumpAndSettle();

        // Tap close button while dirty
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Dirty guard dialog should appear
        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);
        expect(find.text('Perubahan belum disimpan'), findsOneWidget);

        // Tap "Lanjut Mengedit" to cancel dismiss
        await tester.tap(find.text('Lanjut Mengedit'));
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsNothing);
        expect(closed, isFalse);

        // Tap close button again
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Confirm discard
        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);
        await tester.tap(find.text('Buang Perubahan'));
        await tester.pumpAndSettle();

        expect(closed, isTrue);
      },
    );

    testWidgets('cold edit loads record by ID and populates fields', (
      tester,
    ) async {
      when(
        () => mockTrackingRepository.getCutFillRecordById('cf-test-1'),
      ).thenAnswer((_) async => testRecord);

      await tester.pumpWidget(createWidgetUnderTest(recordId: 'cf-test-1'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Pengukuran'), findsOneWidget);
      expect(find.text('Zona: zone-1'), findsOneWidget);
      expect(find.text('Existing test note'), findsOneWidget);
      expect(find.text('-2.5'), findsOneWidget);
    });

    testWidgets(
      'cold edit shows recoverable AppStatePanel when record not found',
      (tester) async {
        when(
          () => mockTrackingRepository.getCutFillRecordById('cf-non-existent'),
        ).thenAnswer((_) async => null);

        bool closed = false;
        await tester.pumpWidget(
          createWidgetUnderTest(
            recordId: 'cf-non-existent',
            onClose: () => closed = true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppStatePanel), findsOneWidget);
        expect(find.text('Data Tidak Ditemukan'), findsOneWidget);
        expect(find.text('Kembali ke daftar'), findsOneWidget);

        await tester.tap(find.text('Kembali ke daftar'));
        await tester.pumpAndSettle();

        expect(closed, isTrue);
      },
    );

    testWidgets(
      'responsive geometry: renders right sheet on desktop and bottom sheet on mobile',
      (tester) async {
        // Desktop viewport (>= 800dp)
        await tester.pumpWidget(
          createWidgetUnderTest(size: const Size(1024, 768)),
        );
        await tester.pumpAndSettle();

        final desktopSheetFinder = find.byWidgetPredicate(
          (w) => w is Align && w.alignment == Alignment.centerRight,
        );
        expect(desktopSheetFinder, findsOneWidget);

        // Mobile viewport (< 800dp)
        await tester.pumpWidget(
          createWidgetUnderTest(size: const Size(400, 800)),
        );
        await tester.pumpAndSettle();

        final mobileSheetFinder = find.byWidgetPredicate(
          (w) => w is Align && w.alignment == Alignment.bottomCenter,
        );
        expect(mobileSheetFinder, findsOneWidget);
      },
    );

    testWidgets(
      'validation failure shows toast when required fields are missing',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Attempt save without selecting zone
        await tester.tap(find.byKey(const Key('save_cut_fill_button')));
        await tester.pumpAndSettle();

        // FToast should show error message
        expect(find.text('Pilih zona terlebih dahulu.'), findsOneWidget);
        verifyNever(() => mockTrackingRepository.saveCutFillRecord(any()));
      },
    );

    testWidgets(
      'dirty dismissal via scrim tap triggers AppDirtyDismissDialog',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Mutate form by entering BCM volume
        final bcmInput = find.byType(TextField).first;
        await tester.enterText(bcmInput, '120');
        await tester.pumpAndSettle();

        // Tap barrier scrim at top-left
        await tester.tapAt(const Offset(50, 50));
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);
        expect(find.text('Perubahan belum disimpan'), findsOneWidget);

        // Continue editing
        await tester.tap(find.text('Lanjut Mengedit'));
        await tester.pumpAndSettle();
        expect(find.byType(AppDirtyDismissDialog), findsNothing);
      },
    );

    testWidgets(
      'dirty dismissal via system back triggers AppDirtyDismissDialog',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Mutate form by entering BCM volume
        final bcmInput = find.byType(TextField).first;
        await tester.enterText(bcmInput, '140');
        await tester.pumpAndSettle();

        // Trigger system back
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);
        expect(find.text('Perubahan belum disimpan'), findsOneWidget);
      },
    );

    testWidgets('failed save shows error toast and retains user inputs', (
      tester,
    ) async {
      when(
        () => mockTrackingRepository.saveCutFillRecord(any()),
      ).thenThrow(Exception('Simulated database write failure'));

      await tester.pumpWidget(
        createWidgetUnderTest(existingRecord: testRecord),
      );
      await tester.pumpAndSettle();

      // Mutate notes via Key
      await tester.enterText(
        find.byKey(const Key('cut_fill_notes_input')),
        'Modified note for retry',
      );
      await tester.pumpAndSettle();

      // Attempt save
      await tester.tap(find.byKey(const Key('save_cut_fill_button')));
      await tester.pumpAndSettle();

      // Error toast shown
      expect(
        find.textContaining('Gagal menyimpan data cut/fill'),
        findsOneWidget,
      );

      // Verify mutated note is retained in input field
      expect(find.text('Modified note for retry'), findsOneWidget);
      expect(find.text('-2.5'), findsOneWidget);
    });

    testWidgets('routeUri with zoneId query parameter pre-selects zone', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          routeUri: Uri.parse('/operations/cut-fill/form?zoneId=zone-2'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zona: zone-2'), findsOneWidget);
    });
  });
}
