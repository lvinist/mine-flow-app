import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

/// Abstract repository contract for field tracking & measurements operations
/// covering Earthwork Cut/Fill, Land Clearing, and Inventory.
abstract class TrackingRepository {
  // --- Cut / Fill Operations ---
  Future<List<CutFillRecord>> getCutFillRecords({
    String? siteId,
    String? zoneId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<CutFillRecord?> getCutFillRecordById(String id);

  Future<void> saveCutFillRecord(CutFillRecord record);

  Future<void> deleteCutFillRecord(String id);

  // --- Land Clearing Operations ---
  Future<List<LandClearingRecord>> getLandClearingRecords({
    String? siteId,
    String? zoneId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<LandClearingRecord?> getLandClearingRecordById(String id);

  Future<void> saveLandClearingRecord(LandClearingRecord record);

  Future<void> deleteLandClearingRecord(String id);

  // --- Inventory Operations ---
  Future<List<InventoryItem>> getInventoryItems({
    String? siteId,
    String? zoneId,
    String? category,
  });

  Future<InventoryItem?> getInventoryItemById(String id);

  Future<void> saveInventoryItem(InventoryItem item);

  Future<void> updateInventoryQuantity(String id, double deltaQuantity);

  Future<void> deleteInventoryItem(String id);

  // --- Synchronization ---
  Future<void> syncRemote();
}
