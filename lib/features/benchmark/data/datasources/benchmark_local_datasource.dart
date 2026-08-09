import 'package:hive/hive.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';

/// Local data source providing Hive-backed offline caching for benchmark data.
///
/// Uses a Hive box (opened in `AppInitializer`) to persist [BenchmarkModel]
/// instances for offline access via toHiveJson/fromHiveJson serialization.
abstract class BenchmarkLocalDataSource {
  /// Returns all cached benchmarks from the local Hive box.
  List<BenchmarkModel> getBenchmarks();

  /// Returns a single benchmark by [id], or null if not found.
  BenchmarkModel? getBenchmarkById(String id);

  /// Persists or updates [benchmark] in the local Hive box.
  Future<void> saveBenchmark(BenchmarkModel benchmark);

  /// Persists a batch of [benchmarks] in a single Hive transaction.
  Future<void> saveBenchmarkBatch(List<BenchmarkModel> benchmarks);

  /// Deletes a benchmark by [id] from the local Hive box.
  Future<void> deleteBenchmark(String id);
}

/// Concrete implementation of [BenchmarkLocalDataSource] backed by a Hive box.
///
/// Serializes [BenchmarkModel] to/from JSON maps stored in a
/// `Box<Map<String, dynamic>>` — avoids needing a Hive TypeAdapter per
/// the project convention (see DataBucketLocalDataSourceImpl).
class BenchmarkLocalDataSourceImpl implements BenchmarkLocalDataSource {
  final Box<Map<String, dynamic>> _hiveBox;

  /// Creates a [BenchmarkLocalDataSourceImpl] with the given [Hive] box.
  BenchmarkLocalDataSourceImpl({required this._hiveBox});

  @override
  List<BenchmarkModel> getBenchmarks() {
    return _hiveBox.values
        .map(
          (value) =>
              BenchmarkModel.fromHiveJson(Map<String, dynamic>.from(value)),
        )
        .toList();
  }

  @override
  BenchmarkModel? getBenchmarkById(String id) {
    final value = _hiveBox.get(id);
    if (value == null) return null;
    return BenchmarkModel.fromHiveJson(Map<String, dynamic>.from(value));
  }

  @override
  Future<void> saveBenchmark(BenchmarkModel benchmark) async {
    await _hiveBox.put(benchmark.id, benchmark.toHiveJson());
  }

  @override
  Future<void> saveBenchmarkBatch(List<BenchmarkModel> benchmarks) async {
    final map = {for (final b in benchmarks) b.id: b.toHiveJson()};
    await _hiveBox.putAll(map);
  }

  @override
  Future<void> deleteBenchmark(String id) async {
    await _hiveBox.delete(id);
  }
}
