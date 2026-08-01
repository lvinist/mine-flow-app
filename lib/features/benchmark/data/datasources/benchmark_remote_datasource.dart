import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mine_flow/features/benchmark/data/models/benchmark_model.dart';

/// Remote data source accessing Supabase `benchmarks` table.
///
/// Provides CRUD operations and a real-time subscription stream for the
/// Benchmark (survey control point) entity.
abstract class BenchmarkRemoteDataSource {
  /// Fetches all benchmarks (non-deleted) from Supabase, optionally filtered
  /// by [status].
  Future<List<BenchmarkModel>> fetchBenchmarks({String? status});

  /// Creates or updates a benchmark record.
  Future<BenchmarkModel> saveBenchmark(BenchmarkModel benchmark);

  /// Soft-deletes a benchmark record (sets status to "deleted").
  Future<void> deleteBenchmark(String id);

  /// Returns a stream of benchmark records for real-time updates.
  Stream<List<BenchmarkModel>> watchBenchmarks();
}

class BenchmarkRemoteDataSourceImpl implements BenchmarkRemoteDataSource {
  final SupabaseClient supabaseClient;

  BenchmarkRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<BenchmarkModel>> fetchBenchmarks({String? status}) async {
    var query = supabaseClient.from('benchmarks').select();

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => BenchmarkModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BenchmarkModel> saveBenchmark(BenchmarkModel benchmark) async {
    final response = await supabaseClient
        .from('benchmarks')
        .upsert(benchmark.toJson())
        .select()
        .single();

    return BenchmarkModel.fromJson(response);
  }

  @override
  Future<void> deleteBenchmark(String id) async {
    await supabaseClient
        .from('benchmarks')
        .update({'status': 'deleted'})
        .eq('id', id);
  }

  @override
  Stream<List<BenchmarkModel>> watchBenchmarks() {
    return supabaseClient
        .from('benchmarks')
        .stream(primaryKey: ['id'])
        .map(
          (response) => (response as List)
              .where((row) => row['status'] != 'deleted')
              .map(
                (json) => BenchmarkModel.fromJson(json as Map<String, dynamic>),
              )
              .toList(),
        );
  }
}
