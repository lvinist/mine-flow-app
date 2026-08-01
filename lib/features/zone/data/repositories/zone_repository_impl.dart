import 'package:mine_flow/core/data/models/zone_model.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/zone/data/datasources/zone_local_datasource.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';

/// Implementation of [ZoneRepository] coordinating local Hive storage and
/// [SyncQueueManager] for offline-first zone mutations.
///
/// Follows the same offline-first pattern as [TrackingRepositoryImpl]
/// and other feature repositories in the project.
class ZoneRepositoryImpl implements ZoneRepository {
  final ZoneLocalDataSource localDataSource;
  final SyncQueueManager syncQueueManager;
  final NetworkInfo networkInfo;

  /// Creates a [ZoneRepositoryImpl] with the required dependencies.
  ZoneRepositoryImpl({
    required this.localDataSource,
    required this.syncQueueManager,
    required this.networkInfo,
  });

  @override
  List<ZoneEntity> getZones() {
    return localDataSource
        .getZones()
        .where((model) => model.deletedAt == null)
        .map((model) => model.toDomain())
        .toList();
  }

  @override
  ZoneEntity? getZoneById(String id) {
    final model = localDataSource.getZoneById(id);
    if (model == null || model.deletedAt != null) return null;
    return model.toDomain();
  }

  @override
  Future<void> saveZone(ZoneEntity zone) async {
    final updatedZone = zone.updatedAt == null
        ? zone.copyWith(updatedAt: DateTime.now())
        : zone;
    final model = ZoneModel.fromDomain(updatedZone);

    await localDataSource.saveZone(model);

    await syncQueueManager.enqueueMutation(
      entityType: 'zones',
      action: SyncAction.update,
      payloadJson: model.toJson(),
      timestamp: model.updatedAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> deleteZone(String id) async {
    final existing = localDataSource.getZoneById(id);
    if (existing != null) {
      final softDeletedModel = ZoneModel(
        id: existing.id,
        siteId: existing.siteId,
        name: existing.name,
        category: existing.category,
        description: existing.description,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      await localDataSource.saveZone(softDeletedModel);
    } else {
      await localDataSource.deleteZone(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'zones',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: DateTime.now(),
    );
  }
}
