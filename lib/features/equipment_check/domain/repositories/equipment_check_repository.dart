import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Repository interface for managing SOP digital equipment checks.
abstract class EquipmentCheckRepository {
  Future<List<EquipmentCheck>> getEquipmentChecks({
    String? siteId,
    EquipmentType? equipmentType,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<EquipmentCheck?> getEquipmentCheckById(String id);

  Future<void> saveEquipmentCheck(EquipmentCheck check);

  Future<void> saveEquipmentCheckBatch(List<EquipmentCheck> checks);

  Future<void> deleteEquipmentCheck(String id);

  Future<List<EquipmentCheck>> syncRemote();
}
