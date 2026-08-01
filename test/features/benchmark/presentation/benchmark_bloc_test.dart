/// Unit tests for [BenchmarkBloc].
///
/// Tests all events: loading, CRUD operations, form state management,
/// automatic Lat/Lon computation, and error handling.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mine_flow/features/benchmark/presentation/bloc/benchmark_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockBenchmarkRepository extends Mock implements BenchmarkRepository {}

final _emptyBenchmarks = <Benchmark>[];

void main() {
  late MockBenchmarkRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      const Benchmark(
        id: 'fallback',
        bmId: 'FB-000',
        northing: 0,
        easting: 0,
        orthoHeight: 0,
        code: '',
        orde: '',
        latitude: 0,
        longitude: 0,
        ellipsHeight: 0,
        status: '',
      ),
    );
  });

  setUp(() {
    mockRepository = MockBenchmarkRepository();
  });

  group('BenchmarkBloc', () {
    blocTest<BenchmarkBloc, BenchmarkState>(
      'emits [Loading, ListLoaded] when LoadBenchmarks succeeds',
      build: () {
        when(
          () => mockRepository.getBenchmarks(),
        ).thenAnswer((_) async => _emptyBenchmarks);
        return BenchmarkBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadBenchmarks()),
      expect: () => [isA<BenchmarkLoading>(), isA<BenchmarkListLoaded>()],
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'emits [Loading, Error] when LoadBenchmarks fails',
      build: () {
        when(
          () => mockRepository.getBenchmarks(),
        ).thenThrow(Exception('Network error'));
        return BenchmarkBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadBenchmarks()),
      expect: () => [isA<BenchmarkLoading>(), isA<BenchmarkError>()],
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'emits FormState with default values when CreateBenchmark is fired',
      build: () => BenchmarkBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const CreateBenchmark()),
      expect: () => [isA<BenchmarkFormState>()],
      verify: (bloc) {
        final state = bloc.state as BenchmarkFormState;
        expect(state.bmId, '');
        expect(state.northing, 0.0);
        expect(state.easting, 0.0);
        expect(state.crsIdentifier, 'UTM Zone 51S');
        expect(state.status, 'active');
        expect(state.isEditing, false);
        expect(state.computedLatitude, isNotNull);
        expect(state.computedLongitude, isNotNull);
      },
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'emits FormState with pre-filled values when EditBenchmark is fired',
      build: () => BenchmarkBloc(repository: mockRepository),
      act: (bloc) => bloc.add(
        const EditBenchmark(
          Benchmark(
            id: 'test-id',
            bmId: 'BM-001',
            northing: 9_200_000.0,
            easting: 700_000.0,
            orthoHeight: 100.0,
            code: 'Pilar',
            orde: '1st Order',
            latitude: -7.25,
            longitude: 112.75,
            ellipsHeight: 105.0,
            status: 'active',
          ),
        ),
      ),
      expect: () => [isA<BenchmarkFormState>()],
      verify: (bloc) {
        final state = bloc.state as BenchmarkFormState;
        expect(state.bmId, 'BM-001');
        expect(state.northing, 9_200_000.0);
        expect(state.easting, 700_000.0);
        expect(state.code, 'Pilar');
        expect(state.orde, '1st Order');
        expect(state.isEditing, true);
      },
    );
  });

  group('Form field events', () {
    blocTest<BenchmarkBloc, BenchmarkState>(
      'computes Lat/Lon when Northing changes',
      build: () => BenchmarkBloc(repository: mockRepository),
      seed: () => const BenchmarkFormState(
        bmId: 'BM-001',
        northing: 9_200_000.0,
        easting: 700_000.0,
        orthoHeight: 0.0,
        code: '',
        orde: '',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 0.0,
        status: 'active',
      ),
      act: (bloc) => bloc.add(const FormNorthingChanged(9_210_000.0)),
      expect: () => [isA<BenchmarkFormState>()],
      verify: (bloc) {
        final state = bloc.state as BenchmarkFormState;
        expect(state.northing, 9_210_000.0);
        // Lat/Lon should be recomputed
        expect(state.computedLatitude, isNotNull);
        expect(state.computedLongitude, isNotNull);
      },
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'computes Lat/Lon when Easting changes',
      build: () => BenchmarkBloc(repository: mockRepository),
      seed: () => const BenchmarkFormState(
        bmId: 'BM-001',
        northing: 9_200_000.0,
        easting: 700_000.0,
        orthoHeight: 0.0,
        code: '',
        orde: '',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 0.0,
        status: 'active',
      ),
      act: (bloc) => bloc.add(const FormEastingChanged(710_000.0)),
      expect: () => [isA<BenchmarkFormState>()],
      verify: (bloc) {
        final state = bloc.state as BenchmarkFormState;
        expect(state.easting, 710_000.0);
        expect(state.computedLatitude, isNotNull);
        expect(state.computedLongitude, isNotNull);
      },
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'recomputes Lat/Lon when CRS changes',
      build: () => BenchmarkBloc(repository: mockRepository),
      seed: () => const BenchmarkFormState(
        bmId: 'BM-001',
        northing: 9_200_000.0,
        easting: 700_000.0,
        orthoHeight: 0.0,
        code: '',
        orde: '',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 0.0,
        status: 'active',
      ),
      act: (bloc) => bloc.add(const FormCrsChanged('UTM Zone 50S')),
      expect: () => [isA<BenchmarkFormState>()],
      verify: (bloc) {
        final state = bloc.state as BenchmarkFormState;
        expect(state.crsIdentifier, 'UTM Zone 50S');
      },
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'updates BM ID when FormBmIdChanged fires',
      build: () => BenchmarkBloc(repository: mockRepository),
      seed: () => const BenchmarkFormState(
        bmId: '',
        northing: 0.0,
        easting: 0.0,
        orthoHeight: 0.0,
        code: '',
        orde: '',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 0.0,
        status: 'active',
      ),
      act: (bloc) => bloc.add(const FormBmIdChanged('BM-002')),
      expect: () => [isA<BenchmarkFormState>()],
      verify: (bloc) {
        expect((bloc.state as BenchmarkFormState).bmId, 'BM-002');
      },
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'returns Error when submitting with empty BM ID',
      build: () => BenchmarkBloc(repository: mockRepository),
      seed: () => const BenchmarkFormState(
        bmId: '',
        northing: 0.0,
        easting: 0.0,
        orthoHeight: 0.0,
        code: '',
        orde: '',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 0.0,
        status: 'active',
      ),
      act: (bloc) => bloc.add(const SubmitBenchmark()),
      expect: () => [isA<BenchmarkError>()],
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'calls saveBenchmark and emits Success when SubmitBenchmark fires',
      build: () {
        when(
          () => mockRepository.saveBenchmark(any()),
        ).thenAnswer((_) async {});
        return BenchmarkBloc(repository: mockRepository);
      },
      seed: () => const BenchmarkFormState(
        bmId: 'BM-001',
        northing: 9_200_000.0,
        easting: 700_000.0,
        orthoHeight: 100.0,
        code: 'Pilar',
        orde: '1st Order',
        crsIdentifier: 'UTM Zone 51S',
        ellipsHeight: 105.0,
        status: 'active',
        computedLatitude: -7.25,
        computedLongitude: 112.75,
      ),
      act: (bloc) => bloc.add(const SubmitBenchmark()),
      expect: () => [isA<BenchmarkSuccess>()],
      verify: (bloc) {
        verify(() => mockRepository.saveBenchmark(any())).called(1);
      },
    );
  });

  group('Delete and Refresh', () {
    blocTest<BenchmarkBloc, BenchmarkState>(
      'reloads benchmarks after DeleteBenchmark',
      build: () {
        when(
          () => mockRepository.deleteBenchmark(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.getBenchmarks(),
        ).thenAnswer((_) async => _emptyBenchmarks);
        return BenchmarkBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const DeleteBenchmark('test-id')),
      expect: () => [isA<BenchmarkLoading>(), isA<BenchmarkListLoaded>()],
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'emits error when DeleteBenchmark fails',
      build: () {
        when(
          () => mockRepository.deleteBenchmark(any()),
        ).thenThrow(Exception('Delete failed'));
        return BenchmarkBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const DeleteBenchmark('test-id')),
      expect: () => [isA<BenchmarkError>()],
      verify: (bloc) {
        final state = bloc.state as BenchmarkError;
        expect(state.message, contains('Gagal menghapus'));
      },
    );

    blocTest<BenchmarkBloc, BenchmarkState>(
      'loads benchmarks on RefreshBenchmarks',
      build: () {
        when(
          () => mockRepository.getBenchmarks(),
        ).thenAnswer((_) async => _emptyBenchmarks);
        return BenchmarkBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const RefreshBenchmarks()),
      expect: () => [isA<BenchmarkLoading>(), isA<BenchmarkListLoaded>()],
    );
  });
}
