import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Data Transfer Object for [EquipmentCheck] handling JSON serialization
/// to/from Supabase `public.equipment_checks` table and Hive local storage.
class EquipmentCheckDto {
  final String id;
  final String siteId;
  final String foremanId;
  final String equipmentType;
  final String? serialNumber;
  final DateTime checkTime;
  final String checkType;
  final String status;
  final bool isOperational;
  final List<Map<String, dynamic>> checklistData;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const EquipmentCheckDto({
    required this.id,
    required this.siteId,
    required this.foremanId,
    required this.equipmentType,
    this.serialNumber,
    required this.checkTime,
    required this.checkType,
    required this.status,
    this.isOperational = true,
    this.checklistData = const [],
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Deserializes JSON map from Supabase DB or Hive cache string.
  factory EquipmentCheckDto.fromJson(Map<String, dynamic> json) {
    final rawCheckTime = json['check_time'] as String?;
    final rawChecklist =
        json['checklist_data'] as List<dynamic>? ??
        json['checklist'] as List<dynamic>? ??
        [];

    final parsedChecklist = rawChecklist.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      } else if (item is Map) {
        return Map<String, dynamic>.from(item);
      }
      return <String, dynamic>{};
    }).toList();

    return EquipmentCheckDto(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      foremanId:
          json['foreman_id'] as String? ?? json['user_id'] as String? ?? '',
      equipmentType: json['equipment_type'] as String? ?? 'gnss',
      serialNumber: json['serial_number'] as String?,
      checkTime: rawCheckTime != null
          ? DateTime.tryParse(rawCheckTime) ?? DateTime.now()
          : DateTime.now(),
      checkType: json['check_type'] as String? ?? 'pre_work',
      status:
          json['status'] as String? ??
          ((json['is_operational'] as bool? ?? true) ? 'passed' : 'flagged'),
      isOperational: json['is_operational'] as bool? ?? true,
      checklistData: parsedChecklist,
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

  /// Serializes DTO to JSON map suitable for Supabase queries and SyncQueue payload.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'foreman_id': foremanId,
      'equipment_type': equipmentType,
      if (serialNumber != null) 'serial_number': serialNumber,
      'check_time': checkTime.toIso8601String(),
      'check_type': checkType,
      'status': status,
      'is_operational': isOperational,
      'checklist_data': checklistData,
      if (remarks != null) 'remarks': remarks,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts DTO into domain entity [EquipmentCheck].
  EquipmentCheck toDomain() {
    final items = checklistData
        .map((json) => CheckItem.fromJson(json))
        .toList();

    return EquipmentCheck(
      id: id,
      siteId: siteId,
      foremanId: foremanId,
      equipmentType: EquipmentType.fromString(equipmentType),
      serialNumber: serialNumber,
      checkTime: checkTime,
      checkType: CheckType.fromString(checkType),
      status: CheckStatus.fromString(status),
      isOperational: isOperational,
      checklist: items,
      remarks: remarks,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Creates DTO from domain entity [EquipmentCheck].
  factory EquipmentCheckDto.fromDomain(EquipmentCheck entity) {
    final rawChecklist = entity.checklist.map((item) => item.toJson()).toList();

    return EquipmentCheckDto(
      id: entity.id,
      siteId: entity.siteId,
      foremanId: entity.foremanId,
      equipmentType: entity.equipmentType.toValue(),
      serialNumber: entity.serialNumber,
      checkTime: entity.checkTime,
      checkType: entity.checkType.toValue(),
      status: entity.status.toValue(),
      isOperational: entity.isOperational,
      checklistData: rawChecklist,
      remarks: entity.remarks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }
}
