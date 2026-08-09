import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';

/// Abstract repository contract for Benchmark (survey control point) operations.
///
/// Defines the boundary between the domain and data layers. Implementations
/// coordinate between local (Hive) and remote (Supabase) data sources with
/// offline-first semantics.
abstract class BenchmarkRepository {
  /// Retrieves all benchmarks, optionally filtered by [status].
  Future<List<Benchmark>> getBenchmarks({String? status});

  /// Retrieves a single benchmark by its [id] (UUID).
  Future<Benchmark?> getBenchmarkById(String id);

  /// Saves a [benchmark] — creates or updates depending on whether the ID
  /// already exists locally or remotely. Supports offline creation: records
  /// with a client-generated UUID are queued for sync.
  Future<void> saveBenchmark(Benchmark benchmark);

  /// Deletes the benchmark with the given [id]. Supports soft-delete via
  /// status changes when the record has already been synced remotely.
  Future<void> deleteBenchmark(String id);

  /// Synchronises local changes to the remote Supabase backend.
  /// Uploads newly created records and pushes updates for dirty records.
  Future<void> syncRemote();
}
