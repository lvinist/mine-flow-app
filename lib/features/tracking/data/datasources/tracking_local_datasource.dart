import 'package:mine_flow/core/offline/hive_cache_repository.dart';
import 'package:mine_flow/core/data/models/cut_fill_record_model.dart';
import 'package:mine_flow/core/data/models/land_clearing_record_model.dart';
import 'package:mine_flow/core/data/models/inventory_item_model.dart'
    as core_models;
import 'package:mine_flow/features/tracking/data/models/cut_fill_model.dart';
import 'package:mine_flow/features/tracking/data/models/inventory_item_model.dart';
import 'package:mine_flow/features/tracking/data/models/land_clearing_model.dart';

/// Local data source wrapping HiveCacheRepository for offline caching.
abstract class TrackingLocalDataSource {
  // Cut/Fill
  List<CutFillModel> getCutFillRecords();
  CutFillModel? getCutFillRecordById(String id);
  Future<void> saveCutFillRecord(CutFillModel record);
  Future<void> saveCutFillRecordBatch(List<CutFillModel> records);
  Future<void> deleteCutFillRecord(String id);

  // Land Clearing
  List<LandClearingModel> getLandClearingRecords();
  LandClearingModel? getLandClearingRecordById(String id);
  Future<void> saveLandClearingRecord(LandClearingModel record);
  Future<void> saveLandClearingRecordBatch(List<LandClearingModel> records);
  Future<void> deleteLandClearingRecord(String id);

  // Inventory
  List<InventoryItemModel> getInventoryItems();
  InventoryItemModel? getInventoryItemById(String id);
  Future<void> saveInventoryItem(InventoryItemModel item);
  Future<void> saveInventoryItemBatch(List<InventoryItemModel> items);
  Future<void> deleteInventoryItem(String id);
}

class TrackingLocalDataSourceImpl implements TrackingLocalDataSource {
  final HiveCacheRepository<CutFillRecordModel> cutFillCache;
  final HiveCacheRepository<LandClearingRecordModel> landClearingCache;
  final HiveCacheRepository<core_models.InventoryItemModel> inventoryCache;

  TrackingLocalDataSourceImpl({
    required this.cutFillCache,
    required this.landClearingCache,
    required this.inventoryCache,
  });

  // --- Cut / Fill ---
  @override
  List<CutFillModel> getCutFillRecords() {
    return cutFillCache
        .getAll()
        .map((core) => CutFillModel.fromCoreModel(core))
        .toList();
  }

  @override
  CutFillModel? getCutFillRecordById(String id) {
    final core = cutFillCache.get(id);
    if (core == null) return null;
    return CutFillModel.fromCoreModel(core);
  }

  @override
  Future<void> saveCutFillRecord(CutFillModel record) async {
    await cutFillCache.put(record.id, record.toCoreModel());
  }

  @override
  Future<void> saveCutFillRecordBatch(List<CutFillModel> records) async {
    final map = {for (final r in records) r.id: r.toCoreModel()};
    await cutFillCache.putAll(map);
  }

  @override
  Future<void> deleteCutFillRecord(String id) async {
    await cutFillCache.delete(id);
  }

  // --- Land Clearing ---
  @override
  List<LandClearingModel> getLandClearingRecords() {
    return landClearingCache
        .getAll()
        .map((core) => LandClearingModel.fromCoreModel(core))
        .toList();
  }

  @override
  LandClearingModel? getLandClearingRecordById(String id) {
    final core = landClearingCache.get(id);
    if (core == null) return null;
    return LandClearingModel.fromCoreModel(core);
  }

  @override
  Future<void> saveLandClearingRecord(LandClearingModel record) async {
    await landClearingCache.put(record.id, record.toCoreModel());
  }

  @override
  Future<void> saveLandClearingRecordBatch(
    List<LandClearingModel> records,
  ) async {
    final map = {for (final r in records) r.id: r.toCoreModel()};
    await landClearingCache.putAll(map);
  }

  @override
  Future<void> deleteLandClearingRecord(String id) async {
    await landClearingCache.delete(id);
  }

  // --- Inventory ---
  @override
  List<InventoryItemModel> getInventoryItems() {
    return inventoryCache
        .getAll()
        .map((core) => InventoryItemModel.fromCoreModel(core))
        .toList();
  }

  @override
  InventoryItemModel? getInventoryItemById(String id) {
    final core = inventoryCache.get(id);
    if (core == null) return null;
    return InventoryItemModel.fromCoreModel(core);
  }

  @override
  Future<void> saveInventoryItem(InventoryItemModel item) async {
    await inventoryCache.put(item.id, item.toCoreModel());
  }

  @override
  Future<void> saveInventoryItemBatch(List<InventoryItemModel> items) async {
    final map = {for (final item in items) item.id: item.toCoreModel()};
    await inventoryCache.putAll(map);
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    await inventoryCache.delete(id);
  }
}
