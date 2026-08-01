import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';

class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockZoneRepository mockRepository;
  late ZoneCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      const ZoneEntity(id: 'fallback', siteId: 'fallback', name: 'fallback'),
    );
  });

  final testZones = [
    ZoneEntity(
      id: 'zone-1',
      siteId: 'site-1',
      name: 'Pit A - Utama (North Cut)',
      category: 'Pit',
      createdAt: DateTime(2026, 7, 23),
      updatedAt: DateTime(2026, 7, 23),
    ),
    ZoneEntity(
      id: 'zone-2',
      siteId: 'site-1',
      name: 'Stockpile 1 (ROM)',
      category: 'Stockpile',
      createdAt: DateTime(2026, 7, 23),
    ),
  ];

  setUp(() {
    mockRepository = MockZoneRepository();
    cubit = ZoneCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ZoneCubit', () {
    test('initial state is ZoneInitial', () {
      expect(cubit.state, isA<ZoneInitial>());
    });

    group('loadZones', () {
      test(
        'emits [ZoneLoading, ZoneLoaded] when zones are loaded successfully',
        () async {
          when(() => mockRepository.getZones()).thenReturn(testZones);

          final expectedStates = [isA<ZoneLoading>(), isA<ZoneLoaded>()];

          final expectFuture = expectLater(cubit.stream, emitsInOrder(expectedStates));

          await cubit.loadZones();
          await expectFuture;
        },
      );

      test('emits [ZoneLoading, ZoneError] when repository throws', () async {
        when(() => mockRepository.getZones()).thenThrow(Exception('DB error'));

        final expectedStates = [isA<ZoneLoading>(), isA<ZoneError>()];

        final expectFuture = expectLater(cubit.stream, emitsInOrder(expectedStates));

        await cubit.loadZones();
        await expectFuture;
        expect((cubit.state as ZoneError).message, contains('DB error'));
      });

      test('ZoneLoaded contains the correct zones', () async {
        when(() => mockRepository.getZones()).thenReturn(testZones);

        await cubit.loadZones();

        final state = cubit.state;
        expect(state, isA<ZoneLoaded>());
        expect((state as ZoneLoaded).zones, hasLength(2));
        expect((state).zones[0].name, equals('Pit A - Utama (North Cut)'));
        expect((state).zones[1].id, equals('zone-2'));
      });
    });

    group('createZone', () {
      test('creates a zone and reloads the list', () async {
        when(() => mockRepository.getZones()).thenReturn(testZones);
        when(() => mockRepository.saveZone(any())).thenAnswer((_) async {});

        // Load zones first to get into ZoneLoaded state
        await cubit.loadZones();
        expect(cubit.state, isA<ZoneLoaded>());

        // Mock the updated zone list after creation
        final newZone = ZoneEntity(
          id: '00000000-0000-0000-0000-000000000000',
          siteId: '',
          name: 'New Test Zone',
          createdAt: DateTime(2026, 7, 23),
          updatedAt: DateTime(2026, 7, 23),
        );
        when(
          () => mockRepository.getZones(),
        ).thenReturn([...testZones, newZone]);

        final result = await cubit.createZone(name: 'New Test Zone');

        expect(result, isNotNull);
        expect(result!.name, equals('New Test Zone'));
        verify(() => mockRepository.saveZone(any())).called(1);

        final state = cubit.state;
        expect(state, isA<ZoneLoaded>());
        expect((state as ZoneLoaded).zones, hasLength(3));
      });

      test('returns null when not in ZoneLoaded state', () async {
        final result = await cubit.createZone(name: 'Test');

        expect(result, isNull);
        verifyNever(() => mockRepository.saveZone(any()));
      });

      test('emits ZoneError when save fails', () async {
        when(() => mockRepository.getZones()).thenReturn(testZones);
        when(
          () => mockRepository.saveZone(any()),
        ).thenThrow(Exception('Save failed'));

        await cubit.loadZones();
        expect(cubit.state, isA<ZoneLoaded>());

        final result = await cubit.createZone(name: 'Failing Zone');

        expect(result, isNull);
        expect(cubit.state, isA<ZoneError>());
        expect((cubit.state as ZoneError).message, contains('Save failed'));
      });
    });
  });
}
