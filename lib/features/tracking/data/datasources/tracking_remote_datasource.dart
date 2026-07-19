import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mine_flow/features/tracking/data/models/cut_fill_model.dart';
import 'package:mine_flow/features/tracking/data/models/inventory_item_model.dart';
import 'package:mine_flow/features/tracking/data/models/land_clearing_model.dart';

/// Remote data source interfacing with Supabase DB tables:
/// `cut_fill_records`, `land_clearing_records`, and `inventory_items`.
abstract class TrackingRemoteDataSource {
  // --- Cut/Fill ---
  Future<List<CutFillModel>> fetchCutFillRecords();
  Future<CutFillModel> createCutFillRecord(CutFillModel record);
  Future<void> deleteCutFillRecord(String id);

  // --- Land Clearing ---
  Future<List<LandClearingModel>> fetchLandClearingRecords();
  Future<LandClearingModel> createLandClearingRecord(LandClearingModel record);
  Future<void> deleteLandClearingRecord(String id);

  // --- Inventory ---
  Future<List<InventoryItemModel>> fetchInventoryItems();
  Future<InventoryItemModel> saveInventoryItem(InventoryItemModel item);
  Future<void> deleteInventoryItem(String id);
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final SupabaseClient supabaseClient;

  TrackingRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<CutFillModel>> fetchCutFillRecords() async {
    final response = await supabaseClient
        .from('cut_fill_records')
        .select()
        .filter('deleted_at', 'is', null);

    return (response as List)
        .map((json) => CutFillModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CutFillModel> createCutFillRecord(CutFillModel record) async {
    final response = await supabaseClient
        .from('cut_fill_records')
        .upsert(record.toJson())
        .select()
        .single();

    return CutFillModel.fromJson(response);
  }

  @override
  Future<void> deleteCutFillRecord(String id) async {
    await supabaseClient
        .from('cut_fill_records')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<List<LandClearingModel>> fetchLandClearingRecords() async {
    final response = await supabaseClient
        .from('land_clearing_records')
        .select()
        .filter('deleted_at', 'is', null);

    return (response as List)
        .map((json) => LandClearingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LandClearingModel> createLandClearingRecord(LandClearingModel record) async {
    final response = await supabaseClient
        .from('land_clearing_records')
        .upsert(record.toJson())
        .select()
        .single();

    return LandClearingModel.fromJson(response);
  }

  @override
  Future<void> deleteLandClearingRecord(String id) async {
    await supabaseClient
        .from('land_clearing_records')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<List<InventoryItemModel>> fetchInventoryItems() async {
    final response = await supabaseClient
        .from('inventory_items')
        .select()
        .filter('deleted_at', 'is', null);

    return (response as List)
        .map((json) => InventoryItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InventoryItemModel> saveInventoryItem(InventoryItemModel item) async {
    final response = await supabaseClient
        .from('inventory_items')
        .upsert(item.toJson())
        .select()
        .single();

    return InventoryItemModel.fromJson(response);
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    await supabaseClient
        .from('inventory_items')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
