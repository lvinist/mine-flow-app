import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface for Supabase remote queries for `public.equipment_checks`.
abstract class EquipmentCheckRemoteDataSource {
  Future<List<EquipmentCheckDto>> fetchAllEquipmentChecks();
  Future<EquipmentCheckDto?> fetchEquipmentCheckById(String id);
  Future<void> upsertEquipmentCheck(EquipmentCheckDto dto);
  Future<void> deleteEquipmentCheck(String id);
}

class EquipmentCheckRemoteDataSourceImpl
    implements EquipmentCheckRemoteDataSource {
  final SupabaseClient supabaseClient;

  EquipmentCheckRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<EquipmentCheckDto>> fetchAllEquipmentChecks() async {
    final response = await supabaseClient
        .from('equipment_checks')
        .select()
        .filter('deleted_at', 'is', null);
    final data = response as List<dynamic>;
    return data
        .map((json) => EquipmentCheckDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EquipmentCheckDto?> fetchEquipmentCheckById(String id) async {
    final response = await supabaseClient
        .from('equipment_checks')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return EquipmentCheckDto.fromJson(response);
  }

  @override
  Future<void> upsertEquipmentCheck(EquipmentCheckDto dto) async {
    await supabaseClient.from('equipment_checks').upsert(dto.toJson());
  }

  @override
  Future<void> deleteEquipmentCheck(String id) async {
    await supabaseClient
        .from('equipment_checks')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
