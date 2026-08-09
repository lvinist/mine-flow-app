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
          if (startDate != null && dto.checkTime.isBefore(startDate))
            return false;
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
    final updatedCheck = check.updatedAt == null
        ? check.copyWith(updatedAt: DateTime.now())
        : check;
    final dto = EquipmentCheckDto.fromDomain(updatedCheck);

    await localCache.put(dto.id, dto);

    await syncQueueManager.enqueueMutation(
      entityType: 'equipment_checks',
      action: SyncAction.update,
      payloadJson: dto.toJson(),
      timestamp: dto.updatedAt ?? DateTime.now(),
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
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      await localCache.put(id, softDeletedDto);
    } else {
      await localCache.delete(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'equipment_checks',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: DateTime.now(),
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
      final map = <String, EquipmentCheckDto>{
        for (final dto in remoteDtos) dto.id: dto,
      };
      await localCache.putAll(map);
      return remoteDtos.map((dto) => dto.toDomain()).toList();
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
