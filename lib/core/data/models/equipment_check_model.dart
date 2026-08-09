import 'package:mine_flow/core/domain/entities/equipment_check_entity.dart';

/// Data Transfer Object (DTO) for [EquipmentCheckEntity] handling JSON serialization
/// to and from Supabase `public.equipment_checks` table.
class EquipmentCheckModel extends EquipmentCheckEntity {
  const EquipmentCheckModel({
    required super.id,
    required super.siteId,
    required super.foremanId,
    required super.equipmentType,
    super.serialNumber,
    required super.checkTime,
    super.checkType = 'pre_work',
    super.isOperational = true,
    super.checklistData = const {},
    super.remarks,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB.
  factory EquipmentCheckModel.fromJson(Map<String, dynamic> json) {
    return EquipmentCheckModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      foremanId: json['foreman_id'] as String,
      equipmentType: json['equipment_type'] as String,
      serialNumber: json['serial_number'] as String?,
      checkTime: json['check_time'] != null
          ? DateTime.parse(json['check_time'] as String)
          : DateTime.now(),
      checkType: json['check_type'] as String? ?? 'pre_work',
      isOperational: json['is_operational'] as bool? ?? true,
      checklistData: json['checklist_data'] != null
          ? Map<String, dynamic>.from(json['checklist_data'] as Map)
          : const {},
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'] as String)
          : null,
    );
  }

  /// Converts model into JSON map suitable for Supabase queries.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'foreman_id': foremanId,
      'equipment_type': equipmentType,
      if (serialNumber != null) 'serial_number': serialNumber,
      'check_time': checkTime.toIso8601String(),
      'check_type': checkType,
      'is_operational': isOperational,
      'checklist_data': checklistData,
      if (remarks != null) 'remarks': remarks,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  EquipmentCheckEntity toDomain() {
    return EquipmentCheckEntity(
      id: id,
      siteId: siteId,
      foremanId: foremanId,
      equipmentType: equipmentType,
      serialNumber: serialNumber,
      checkTime: checkTime,
      checkType: checkType,
      isOperational: isOperational,
      checklistData: checklistData,
      remarks: remarks,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  EquipmentCheckEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory EquipmentCheckModel.fromDomain(EquipmentCheckEntity entity) {
    return EquipmentCheckModel(
      id: entity.id,
      siteId: entity.siteId,
      foremanId: entity.foremanId,
      equipmentType: entity.equipmentType,
      serialNumber: entity.serialNumber,
      checkTime: entity.checkTime,
      checkType: entity.checkType,
      isOperational: entity.isOperational,
      checklistData: entity.checklistData,
      remarks: entity.remarks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory EquipmentCheckModel.fromEntity(EquipmentCheckEntity entity) =>
      EquipmentCheckModel.fromDomain(entity);
}
