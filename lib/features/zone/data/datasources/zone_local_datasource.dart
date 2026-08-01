import 'package:mine_flow/core/data/models/zone_model.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';

/// Local data source wrapping [HiveCacheRepository] for offline Zone storage.
///
/// Provides direct CRUD operations on [ZoneModel] persisted in the local
/// `zone_box` Hive box. The box is opened and managed by [HiveService].
abstract class ZoneLocalDataSource {
  /// Returns all cached zones from the local Hive box.
  List<ZoneModel> getZones();

  /// Returns a single zone by [id], or null if not found.
  ZoneModel? getZoneById(String id);

  /// Persists or updates [zone] in the local Hive box.
  Future<void> saveZone(ZoneModel zone);

  /// Persists a batch of [zones] in a single Hive transaction.
  Future<void> saveZoneBatch(List<ZoneModel> zones);

  /// Deletes a zone by [id] from the local Hive box.
  Future<void> deleteZone(String id);
}

/// Concrete implementation of [ZoneLocalDataSource] backed by a Hive box.
class ZoneLocalDataSourceImpl implements ZoneLocalDataSource {
  final HiveCacheRepository<ZoneModel> _cache;

  /// Creates a [ZoneLocalDataSourceImpl] with the given [HiveCacheRepository].
  ZoneLocalDataSourceImpl(HiveCacheRepository<ZoneModel> cache)
    : _cache = cache;

  @override
  List<ZoneModel> getZones() {
    return _cache.getAll();
  }

  @override
  ZoneModel? getZoneById(String id) {
    return _cache.get(id);
  }

  @override
  Future<void> saveZone(ZoneModel zone) async {
    await _cache.put(zone.id, zone);
  }

  @override
  Future<void> saveZoneBatch(List<ZoneModel> zones) async {
    final map = {for (final z in zones) z.id: z};
    await _cache.putAll(map);
  }

  @override
  Future<void> deleteZone(String id) async {
    await _cache.delete(id);
  }
}
