import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/benchmark/data/datasources/benchmark_local_datasource.dart';
import 'package:mine_flow/features/benchmark/data/datasources/benchmark_remote_datasource.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';

/// Implementation of [BenchmarkRepository] coordinating local Hive storage and
/// remote Supabase datasources with offline-first semantics.
///
/// Follows the same offline-first pattern as [ZoneRepositoryImpl]
/// and other feature repositories in the project.
class BenchmarkRepositoryImpl implements BenchmarkRepository {
  final BenchmarkLocalDataSource localDataSource;
  final BenchmarkRemoteDataSource remoteDataSource;
  final SyncQueueManager syncQueueManager;
  final NetworkInfo networkInfo;

  /// Creates a [BenchmarkRepositoryImpl] with the required dependencies.
  BenchmarkRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.syncQueueManager,
    required this.networkInfo,
  });

  @override
  Future<List<Benchmark>> getBenchmarks({String? status}) async {
    final models = localDataSource.getBenchmarks();
    var domains = models.map((m) => m.toDomain()).toList();

    if (status != null) {
      domains = domains.where((b) => b.status == status).toList();
    }

    return domains;
  }

  @override
  Future<Benchmark?> getBenchmarkById(String id) async {
    final model = localDataSource.getBenchmarkById(id);
    return model?.toDomain();
  }

  @override
  Future<void> saveBenchmark(Benchmark benchmark) async {
    final model = BenchmarkModel.fromDomain(benchmark);
    await localDataSource.saveBenchmark(model);

    await syncQueueManager.enqueueMutation(
      entityType: 'benchmarks',
      action: SyncAction.update,
      payloadJson: model.toJson(),
      timestamp: DateTime.now(),
    );

    // If online, try to sync immediately
    final isOnline = await networkInfo.isConnected;
    if (isOnline) {
      await remoteDataSource.saveBenchmark(model);
    }
  }

  @override
  Future<void> deleteBenchmark(String id) async {
    final existing = localDataSource.getBenchmarkById(id);
    if (existing != null) {
      // Soft-delete: set status to "deleted"
      final softDeleted = BenchmarkModel(
        id: existing.id,
        bmId: existing.bmId,
        northing: existing.northing,
        easting: existing.easting,
        orthoHeight: existing.orthoHeight,
        code: existing.code,
        orde: existing.orde,
        geom: existing.geom,
        latitude: existing.latitude,
        longitude: existing.longitude,
        ellipsHeight: existing.ellipsHeight,
        status: 'deleted',
      );
      await localDataSource.saveBenchmark(softDeleted);
    } else {
      await localDataSource.deleteBenchmark(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'benchmarks',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> syncRemote() async {
    final isOnline = await networkInfo.isConnected;
    if (!isOnline) return;

    await syncQueueManager.processQueue();
  }
}
