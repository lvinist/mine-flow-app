import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mine_flow/features/data_bucket/data/models/geospatial_file_model.dart';

/// Remote data source accessing Supabase `geospatial_files` table.
///
/// Provides CRUD operations and a real-time subscription stream.
abstract class DataBucketRemoteDataSource {
  /// Fetches all geospatial files (non-deleted) from Supabase.
  Future<List<GeospatialFileModel>> fetchFiles();

  /// Creates or updates a geospatial file record.
  Future<GeospatialFileModel> saveFile(GeospatialFileModel file);

  /// Soft-deletes a geospatial file record.
  Future<void> deleteFile(String id);

  /// Returns a stream of geospatial file records for real-time updates.
  Stream<List<GeospatialFileModel>> watchFiles();
}

class DataBucketRemoteDataSourceImpl implements DataBucketRemoteDataSource {
  final SupabaseClient supabaseClient;

  DataBucketRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<GeospatialFileModel>> fetchFiles() async {
    final response = await supabaseClient
        .from('geospatial_files')
        .select()
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => GeospatialFileModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<GeospatialFileModel> saveFile(GeospatialFileModel file) async {
    final response = await supabaseClient
        .from('geospatial_files')
        .upsert(file.toJson())
        .select()
        .single();

    return GeospatialFileModel.fromJson(response);
  }

  @override
  Future<void> deleteFile(String id) async {
    await supabaseClient
        .from('geospatial_files')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Stream<List<GeospatialFileModel>> watchFiles() {
    return supabaseClient
        .from('geospatial_files')
        .stream(primaryKey: ['id'])
        .map(
          (response) => (response as List)
              .where((row) => row['deleted_at'] == null)
              .map(
                (json) =>
                    GeospatialFileModel.fromJson(json as Map<String, dynamic>),
              )
              .toList(),
        );
  }
}
