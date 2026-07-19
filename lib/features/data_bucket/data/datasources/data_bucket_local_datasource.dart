import 'package:hive/hive.dart';
import 'package:mine_flow/features/data_bucket/data/models/geospatial_file_model.dart';

/// Local data source providing Hive-backed offline caching for geospatial file metadata.
///
/// Uses a Hive box (typically registered in `main.dart` or an injection module)
/// to persist [GeospatialFileModel] instances for offline access.
abstract class DataBucketLocalDataSource {
  /// Returns all cached [GeospatialFileModel] records.
  List<GeospatialFileModel> getFiles();

  /// Retrieves a single [GeospatialFileModel] by its [id], or `null` if not in cache.
  GeospatialFileModel? getFile(String id);

  /// Saves a [GeospatialFileModel] to the local cache.
  Future<void> saveFile(GeospatialFileModel file);

  /// Saves multiple [GeospatialFileModel] records to the local cache in batch.
  Future<void> saveFileBatch(List<GeospatialFileModel> files);

  /// Deletes a [GeospatialFileModel] from the local cache by its [id].
  Future<void> deleteFile(String id);

  /// Clears all cached geospatial file records.
  Future<void> clearAll();
}

/// Concrete implementation of [DataBucketLocalDataSource] backed by a Hive box.
class DataBucketLocalDataSourceImpl implements DataBucketLocalDataSource {
  final Box<Map<String, dynamic>> hiveBox;

  DataBucketLocalDataSourceImpl({required this.hiveBox});

  @override
  List<GeospatialFileModel> getFiles() {
    return hiveBox.values
        .map(
          (value) => GeospatialFileModel.fromHiveJson(
            Map<String, dynamic>.from(value),
          ),
        )
        .toList();
  }

  @override
  GeospatialFileModel? getFile(String id) {
    final value = hiveBox.get(id);
    if (value == null) return null;
    return GeospatialFileModel.fromHiveJson(Map<String, dynamic>.from(value));
  }

  @override
  Future<void> saveFile(GeospatialFileModel file) async {
    await hiveBox.put(file.id, file.toHiveJson());
  }

  @override
  Future<void> saveFileBatch(List<GeospatialFileModel> files) async {
    final map = <String, Map<String, dynamic>>{};
    for (final file in files) {
      map[file.id] = file.toHiveJson();
    }
    await hiveBox.putAll(map);
  }

  @override
  Future<void> deleteFile(String id) async {
    await hiveBox.delete(id);
  }

  @override
  Future<void> clearAll() async {
    await hiveBox.clear();
  }
}
