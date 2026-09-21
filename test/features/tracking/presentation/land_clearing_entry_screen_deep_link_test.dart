import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_inspector_screen.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockTrackingRepository mockTrackingRepository;
  late MockZoneRepository mockZoneRepository;

  setUp(() {
    mockTrackingRepository = MockTrackingRepository();
    mockZoneRepository = MockZoneRepository();
    when(() => mockZoneRepository.getZones()).thenReturn([]);
  });

  Widget wrapWidget(Widget child) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FToaster(child: child!),
        home: child,
      ),
    );
  }

  group('LandClearingEntryScreen Deep Link & Cold Start', () {
    testWidgets('cold edit loads record by ID and populates fields', (
      tester,
    ) async {
      final testRecord = LandClearingRecord(
        id: 'lc-test-1',
        siteId: 'site-1',
        zoneId: 'zone-1',
        method: 'Excavator',
        planArea: 100.0,
        actualArea: 50.0,
        clearingDate: DateTime(2026, 9, 9),
        clearedBy: 'foreman-1',
        createdAt: DateTime(2026, 9, 9),
        notes: 'Existing test note',
      );

      when(
        () => mockTrackingRepository.getLandClearingRecordById('lc-test-1'),
      ).thenAnswer((_) async => testRecord);

      await tester.pumpWidget(
        wrapWidget(
          LandClearingEntryScreen(
            repository: mockTrackingRepository,
            zoneRepository: mockZoneRepository,
            siteId: 'site-1',
            foremanId: 'foreman-1',
            recordId: 'lc-test-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Land Clearing'), findsOneWidget);
      expect(find.text('Zona: zone-1'), findsOneWidget);
    });

    testWidgets(
      'cold edit with invalid recordId shows recoverable AppStatePanel',
      (tester) async {
        bool closed = false;
        await tester.pumpWidget(
          wrapWidget(
            LandClearingEntryScreen(
              repository: mockTrackingRepository,
              zoneRepository: mockZoneRepository,
              siteId: 'site-1',
              foremanId: 'foreman-1',
              recordId: 'invalid/id/test',
              onClose: () => closed = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppStatePanel), findsOneWidget);
        expect(find.text('Data Tidak Ditemukan'), findsOneWidget);
        expect(find.text('ID land clearing tidak valid.'), findsOneWidget);
        expect(find.text('Kembali'), findsOneWidget);

        await tester.tap(find.text('Kembali'));
        await tester.pumpAndSettle();

        expect(closed, isTrue);
      },
    );

    testWidgets(
      'cold edit with not-found recordId shows recoverable AppStatePanel',
      (tester) async {
        when(
          () =>
              mockTrackingRepository.getLandClearingRecordById('non-existent'),
        ).thenAnswer((_) async => null);

        bool closed = false;
        await tester.pumpWidget(
          wrapWidget(
            LandClearingEntryScreen(
              repository: mockTrackingRepository,
              zoneRepository: mockZoneRepository,
              siteId: 'site-1',
              foremanId: 'foreman-1',
              recordId: 'non-existent',
              onClose: () => closed = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppStatePanel), findsOneWidget);
        expect(find.text('Data Tidak Ditemukan'), findsOneWidget);
        expect(find.text('Kembali'), findsOneWidget);

        await tester.tap(find.text('Kembali'));
        await tester.pumpAndSettle();

        expect(closed, isTrue);
      },
    );
  });

  group('LandClearingInspectorScreen Deep Link & Summary Hierarchy', () {
    testWidgets('inspector displays record details hierarchy and actions', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testRecord = LandClearingRecord(
        id: 'lc-insp-1',
        siteId: 'site-1',
        zoneId: 'zone-north',
        method: 'Dozer D85',
        planArea: 250.0,
        actualArea: 240.0,
        clearingDate: DateTime(2026, 9, 15),
        clearedBy: 'foreman-1',
        createdAt: DateTime(2026, 9, 15),
        notes: 'Vegetasi sedang',
      );

      when(
        () => mockTrackingRepository.getLandClearingRecordById('lc-insp-1'),
      ).thenAnswer((_) async => testRecord);

      await tester.pumpWidget(
        wrapWidget(
          LandClearingInspectorScreen(
            repository: mockTrackingRepository,
            recordId: 'lc-insp-1',
            existingRecord: testRecord,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read-only inspector title and subtitle
      expect(find.text('Detail Land Clearing'), findsOneWidget);
      expect(find.text('Zona: zone-north'), findsOneWidget);

      // Section cards
      expect(find.text('Rencana (Plan)'), findsOneWidget);
      expect(find.text('Realisasi (Actual)'), findsOneWidget);
      expect(find.text('Hapus Data'), findsOneWidget);
      expect(find.text('Dozer D85'), findsOneWidget);
    });

    testWidgets('inspector cold start with invalid ID renders AppStatePanel', (
      tester,
    ) async {
      bool closed = false;
      await tester.pumpWidget(
        wrapWidget(
          LandClearingInspectorScreen(
            repository: mockTrackingRepository,
            recordId: 'invalid/id/slash',
            onClose: () => closed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppStatePanel), findsOneWidget);
      expect(find.text('Data Tidak Ditemukan'), findsOneWidget);
      expect(find.text('ID land clearing tidak valid.'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);

      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets(
      'inspector cold start with not-found ID renders AppStatePanel',
      (tester) async {
        when(
          () => mockTrackingRepository.getLandClearingRecordById('unknown-id'),
        ).thenAnswer((_) async => null);

        bool closed = false;
        await tester.pumpWidget(
          wrapWidget(
            LandClearingInspectorScreen(
              repository: mockTrackingRepository,
              recordId: 'unknown-id',
              onClose: () => closed = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppStatePanel), findsOneWidget);
        expect(find.text('Data Tidak Ditemukan'), findsOneWidget);
        expect(find.text('Kembali'), findsOneWidget);

        await tester.tap(find.text('Kembali'));
        await tester.pumpAndSettle();

        expect(closed, isTrue);
      },
    );
  });
}
