import 'package:mine_flow/core/domain/entities/zone_entity.dart';

/// Repository interface for Zone domain operations.
///
/// Abstracts the data source (local Hive cache, remote Supabase) behind a
/// Clean Architecture boundary. The concrete implementation coordinates
/// offline-first storage and optional remote sync.
abstract class ZoneRepository {
  /// Returns all cached zones from the local data source.
  List<ZoneEntity> getZones();

  /// Returns a single zone by [id], or null if not found.
  ZoneEntity? getZoneById(String id);

  /// Persists a new or updated [zone] offline-first:
  /// writes to local Hive cache and enqueues a sync mutation.
  Future<void> saveZone(ZoneEntity zone);

  /// Deletes a zone by [id] offline-first:
  /// soft-deletes locally and enqueues a delete sync mutation.
  Future<void> deleteZone(String id);
}
