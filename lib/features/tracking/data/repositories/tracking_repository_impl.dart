import 'dart:async';

import 'package:mine_flow/core/network/network_info.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/tracking/data/datasources/tracking_local_datasource.dart';
import 'package:mine_flow/features/tracking/data/datasources/tracking_remote_datasource.dart';
import 'package:mine_flow/features/tracking/data/models/cut_fill_model.dart';
import 'package:mine_flow/features/tracking/data/models/inventory_item_model.dart';
import 'package:mine_flow/features/tracking/data/models/land_clearing_model.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';

/// Implementation of [TrackingRepository] coordinating local Hive storage,
/// Supabase REST operations, and SyncQueueManager for offline mutations.
class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingLocalDataSource localDataSource;
  final SyncQueueManager syncQueueManager;
  final NetworkInfo networkInfo;
  final TrackingRemoteDataSource? remoteDataSource;

  TrackingRepositoryImpl({
    required this.localDataSource,
    required this.syncQueueManager,
    required this.networkInfo,
    this.remoteDataSource,
  });

  // --- Cut / Fill Operations ---
  @override
  Future<List<CutFillRecord>> getCutFillRecords({
    String? siteId,
    String? zoneId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final localModels = localDataSource.getCutFillRecords();

    final filtered = localModels
        .where((model) {
          if (model.deletedAt != null) return false;
          if (siteId != null && model.siteId != siteId) return false;
          if (zoneId != null && model.zoneId != zoneId) return false;
          if (startDate != null && model.measurementDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && model.measurementDate.isAfter(endDate)) {
            return false;
          }
          return true;
        })
        .map((model) => model.toDomain())
        .toList();

    unawaited(_refreshIfOnline());

    return filtered;
  }

  @override
  Future<CutFillRecord?> getCutFillRecordById(String id) async {
    final model = localDataSource.getCutFillRecordById(id);
    if (model == null || model.deletedAt != null) return null;
    return model.toDomain();
  }

  @override
  Future<void> saveCutFillRecord(CutFillRecord record) async {
    final updatedRecord = record.updatedAt == null
        ? record.copyWith(updatedAt: DateTime.now())
        : record;
    final model = CutFillModel.fromDomain(updatedRecord);

    await localDataSource.saveCutFillRecord(model);

    await syncQueueManager.enqueueMutation(
      entityType: 'cut_fill_records',
      action: SyncAction.update,
      payloadJson: model.toJson(),
      timestamp: model.updatedAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> deleteCutFillRecord(String id) async {
    final existing = localDataSource.getCutFillRecordById(id);
    if (existing != null) {
      final softDeletedModel = CutFillModel(
        id: existing.id,
        siteId: existing.siteId,
        zoneId: existing.zoneId,
        dailyLogId: existing.dailyLogId,
        bcmVolume: existing.bcmVolume,
        lcmVolume: existing.lcmVolume,
        materialType: existing.materialType,
        elevationChange: existing.elevationChange,
        measurementDate: existing.measurementDate,
        measuredBy: existing.measuredBy,
        notes: existing.notes,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      await localDataSource.saveCutFillRecord(softDeletedModel);
    } else {
      await localDataSource.deleteCutFillRecord(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'cut_fill_records',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: DateTime.now(),
    );
  }

  // --- Land Clearing Operations ---
  @override
  Future<List<LandClearingRecord>> getLandClearingRecords({
    String? siteId,
    String? zoneId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final localModels = localDataSource.getLandClearingRecords();

    final filtered = localModels
        .where((model) {
          if (model.deletedAt != null) return false;
          if (siteId != null && model.siteId != siteId) return false;
          if (zoneId != null && model.zoneId != zoneId) return false;
          if (startDate != null && model.clearingDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && model.clearingDate.isAfter(endDate)) {
            return false;
          }
          return true;
        })
        .map((model) => model.toDomain())
        .toList();

    unawaited(_refreshIfOnline());

    return filtered;
  }

  @override
  Future<LandClearingRecord?> getLandClearingRecordById(String id) async {
    final model = localDataSource.getLandClearingRecordById(id);
    if (model == null || model.deletedAt != null) return null;
    return model.toDomain();
  }

  @override
  Future<void> saveLandClearingRecord(LandClearingRecord record) async {
    final updatedRecord = record.updatedAt == null
        ? record.copyWith(updatedAt: DateTime.now())
        : record;
    final model = LandClearingModel.fromDomain(updatedRecord);

    await localDataSource.saveLandClearingRecord(model);

    await syncQueueManager.enqueueMutation(
      entityType: 'land_clearing_records',
      action: SyncAction.update,
      payloadJson: model.toJson(),
      timestamp: model.updatedAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> deleteLandClearingRecord(String id) async {
    final existing = localDataSource.getLandClearingRecordById(id);
    if (existing != null) {
      final softDeletedModel = LandClearingModel(
        id: existing.id,
        siteId: existing.siteId,
        zoneId: existing.zoneId,
        dailyLogId: existing.dailyLogId,
        planArea: existing.planArea,
        actualArea: existing.actualArea,
        method: existing.method,
        clearingDate: existing.clearingDate,
        clearedBy: existing.clearedBy,
        notes: existing.notes,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      await localDataSource.saveLandClearingRecord(softDeletedModel);
    } else {
      await localDataSource.deleteLandClearingRecord(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'land_clearing_records',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: DateTime.now(),
    );
  }

  // --- Inventory Operations ---
  @override
  Future<List<InventoryItem>> getInventoryItems({
    String? siteId,
    String? zoneId,
    String? category,
  }) async {
    final localModels = localDataSource.getInventoryItems();

    final filtered = localModels
        .where((model) {
          if (model.deletedAt != null) return false;
          if (siteId != null && model.siteId != siteId) return false;
          if (zoneId != null && model.zoneId != zoneId) return false;
          if (category != null && model.category != category) return false;
          return true;
        })
        .map((model) => model.toDomain())
        .toList();

    unawaited(_refreshIfOnline());

    return filtered;
  }

  @override
  Future<InventoryItem?> getInventoryItemById(String id) async {
    final model = localDataSource.getInventoryItemById(id);
    if (model == null || model.deletedAt != null) return null;
    return model.toDomain();
  }

  @override
  Future<void> saveInventoryItem(InventoryItem item) async {
    final updatedItem = item.updatedAt == null
        ? item.copyWith(updatedAt: DateTime.now())
        : item;
    final model = InventoryItemModel.fromDomain(updatedItem);

    await localDataSource.saveInventoryItem(model);

    await syncQueueManager.enqueueMutation(
      entityType: 'inventory_items',
      action: SyncAction.update,
      payloadJson: model.toJson(),
      timestamp: model.updatedAt ?? DateTime.now(),
    );
  }

  @override
  Future<void> updateInventoryQuantity(String id, double deltaQuantity) async {
    final existing = localDataSource.getInventoryItemById(id);
    if (existing != null) {
      final newQuantity = (existing.quantityOnHand + deltaQuantity).clamp(
        0.0,
        double.infinity,
      );
      final updated = existing.copyWith(
        quantityOnHand: newQuantity,
        updatedAt: DateTime.now(),
      );
      await saveInventoryItem(updated);
    }
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    final existing = localDataSource.getInventoryItemById(id);
    if (existing != null) {
      final softDeletedModel = InventoryItemModel(
        id: existing.id,
        siteId: existing.siteId,
        zoneId: existing.zoneId,
        itemName: existing.itemName,
        sku: existing.sku,
        category: existing.category,
        quantityOnHand: existing.quantityOnHand,
        unit: existing.unit,
        minThreshold: existing.minThreshold,
        notes: existing.notes,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );
      await localDataSource.saveInventoryItem(softDeletedModel);
    } else {
      await localDataSource.deleteInventoryItem(id);
    }

    await syncQueueManager.enqueueMutation(
      entityType: 'inventory_items',
      action: SyncAction.delete,
      payloadJson: {'id': id},
      timestamp: DateTime.now(),
    );
  }

  // --- Inventory Auto-predict ---
  @override
  Future<List<String>> getDistinctItemNames(String prefix) async {
    final items = localDataSource.getInventoryItems();
    final names = <String>{};
    final query = prefix.toLowerCase();
    for (final item in items) {
      if (item.deletedAt != null) continue;
      if (item.itemName.toLowerCase().startsWith(query)) {
        names.add(item.itemName);
      }
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  // --- Synchronization ---
  @override
  Future<void> syncRemote() async {
    if (remoteDataSource == null) return;

    final isOnline = await networkInfo.isConnected;
    if (!isOnline) return;

    await syncQueueManager.processQueue();

    try {
      final cutFills = await remoteDataSource!.fetchCutFillRecords();
      await localDataSource.saveCutFillRecordBatch(cutFills);

      final landClearings = await remoteDataSource!.fetchLandClearingRecords();
      await localDataSource.saveLandClearingRecordBatch(landClearings);

      final inventory = await remoteDataSource!.fetchInventoryItems();
      await localDataSource.saveInventoryItemBatch(inventory);
    } catch (_) {}
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
