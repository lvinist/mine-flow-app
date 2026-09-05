import 'dart:async';

import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/equipment_check/data/datasources/equipment_check_remote_datasource.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';

/// Implementation of [EquipmentCheckRepository] enforcing local-first write and read pattern
/// with fallback to local Hive cache, and background sync enqueuing.
class EquipmentCheckRepositoryImpl implements EquipmentCheckRepository {
  final HiveCacheRepository<EquipmentCheckDto> localCache;
  final SyncQueueManager syncQueueManager;
  final NetworkInfo networkInfo;
  final EquipmentCheckRemoteDataSource? remoteDataSource;

  EquipmentCheckRepositoryImpl({
    required this.localCache,
    required this.syncQueueManager,
    required this.networkInfo,
    this.remoteDataSource,
  });

  @override
  Future<List<EquipmentCheck>> getEquipmentChecks({
    String? siteId,
    EquipmentType? equipmentType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allDtos = localCache.getAll();

    final filtered = allDtos
        .where((dto) {
          if (dto.deletedAt != null) return false;
          if (siteId != null && dto.siteId != siteId) return false;
          if (equipmentType != null &&
              dto.equipmentType != equipmentType.toValue()) {
            return false;
          }
          if (startDate != null && dto.checkTime.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && dto.checkTime.isAfter(endDate)) return false;
          return true;
        })
        .map((dto) => dto.toDomain())
        .toList();

    unawaited(_refreshIfOnline());

    return filtered;
  }

  @override
  Future<EquipmentCheck?> getEquipmentCheckById(String id) async {
    final dto = localCache.get(id);
    if (dto == null || dto.deletedAt != null) return null;
    return dto.toDomain();
  }

  @override
  Future<void> saveEquipmentCheck(EquipmentCheck check) async {
    final now = DateTime.now().toUtc();
    final updatedCheck = check.updatedAt == null
        ? check.copyWith(updatedAt: now)
        : check;
    final dto = EquipmentCheckDto.fromDomain(updatedCheck);

    await localCache.put(dto.id, dto);

    await syncQueueManager.enqueueMutation(
      entityType: 'equipment_checks',
      action: SyncAction.update,
      payloadJson: dto.toJson(),
      timestamp: dto.updatedAt ?? now,
    );
  }

  @override
  Future<void> saveEquipmentCheckBatch(List<EquipmentCheck> checks) async {
    for (final check in checks) {
      await saveEquipmentCheck(check);
    }
  }

  @override
  Future<void> deleteEquipmentCheck(String id) async {
    final existing = localCache.get(id);
    final now = DateTime.now().toUtc();
    if (existing != null) {
      final softDeletedDto = EquipmentCheckDto(
        id: existing.id,
        siteId: existing.siteId,
        foremanId: existing.foremanId,
        equipmentType: existing.equipmentType,
        serialNumber: existing.serialNumber,
        checkTime: existing.checkTime,
        checkType: existing.checkType,
        status: existing.status,
        isOperational: existing.isOperational,
        checklistData: existing.checklistData,
        remarks: existing.remarks,
        createdAt: existing.createdAt,
        updatedAt: now,
        deletedAt: now,
      );
      await localCache.put(id, softDeletedDto);
    } else {
      await localCache.delete(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'equipment_checks',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: now,
    );
  }

  @override
  Future<List<EquipmentCheck>> syncRemote() async {
    if (remoteDataSource == null) {
      return localCache.getAll().map((d) => d.toDomain()).toList();
    }

    final isOnline = await networkInfo.isConnected;
    if (!isOnline) {
      return localCache.getAll().map((d) => d.toDomain()).toList();
    }

    try {
      final remoteDtos = await remoteDataSource!.fetchAllEquipmentChecks();
      // STEP-48.27: last-write-wins merge, mirroring the policy
      // TrackingRepositoryImpl._lastWriteWins already applies. An
      // unconditional putAll let a fetch snapshot that STARTED before a local
      // save land AFTER it and clobber the fresher local row; it also let a
      // live remote row resurrect a locally tombstoned check whose delete
      // mutation was still queued.
      final accepted = <String, EquipmentCheckDto>{};
      for (final dto in remoteDtos) {
        final local = localCache.get(dto.id);
        if (local != null) {
          // Remote must be equal-or-newer to win, so genuine server-side
          // corrections still converge; a strictly older snapshot is dropped.
          final remoteIsOlder =
              local.updatedAt != null &&
              dto.updatedAt != null &&
              dto.updatedAt!.isBefore(local.updatedAt!);
          // A pending local soft-delete beats a live remote row; a remote row
          // that is itself deleted is still accepted so tombstones propagate.
          if (local.deletedAt != null && dto.deletedAt == null) continue;
          if (remoteIsOlder) continue;
        }
        accepted[dto.id] = dto;
      }
      await localCache.putAll(accepted);
      // Return the merged cache, not the raw snapshot: a rejected remote row
      // must not be handed back to the caller either.
      return localCache.getAll().map((dto) => dto.toDomain()).toList();
    } catch (_) {
      return localCache.getAll().map((d) => d.toDomain()).toList();
    }
  }

  Future<void> _refreshIfOnline() async {
    final isOnline = await networkInfo.isConnected;
    if (isOnline && remoteDataSource != null) {
      try {
        await syncRemote();
      } catch (_) {}
    }
  }
}
