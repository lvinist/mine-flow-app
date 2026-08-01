import 'package:mine_flow/core/data/models/land_clearing_record_model.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

/// Data Model / DTO for [LandClearingRecord] extending entity and providing JSON serialization.
///
/// v2: Maps plan_area/actual_area instead of area_cleared_m2/area_cleared_ha,
/// and maps method instead of clearing_method/vegetation_type.
class LandClearingModel extends LandClearingRecord {
  const LandClearingModel({
    required super.id,
    required super.siteId,
    required super.zoneId,
    super.dailyLogId,
    super.planArea = 0.0,
    super.actualArea = 0.0,
    super.method,
    required super.clearingDate,
    super.clearedBy,
    super.notes,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB or payload.
  factory LandClearingModel.fromJson(Map<String, dynamic> json) {
    return LandClearingModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      zoneId: json['zone_id'] as String? ?? '',
      dailyLogId: json['daily_log_id'] as String?,
      planArea: (json['plan_area'] as num?)?.toDouble() ?? 0.0,
      actualArea: (json['actual_area'] as num?)?.toDouble() ?? 0.0,
      method:
          (json['method'] ?? json['clearing_method'] ?? json['vegetation_type'])
              as String?,
      clearingDate: json['cleared_at'] != null
          ? DateTime.parse(json['cleared_at'] as String)
          : (json['clearing_date'] != null
                ? DateTime.parse(json['clearing_date'] as String)
                : DateTime.now()),
      clearedBy: (json['cleared_by'] ?? json['created_by']) as String?,
      notes: json['notes'] as String?,
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

  /// Serializes model into JSON map suitable for Supabase queries.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'site_id': siteId,
      'zone_id': zoneId,
      if (dailyLogId != null) 'daily_log_id': dailyLogId,
      'plan_area': planArea,
      'actual_area': actualArea,
      if (method != null) 'method': method,
      if (method != null) 'clearing_method': method,
      if (method != null) 'vegetation_type': method,
      'cleared_at': clearingDate.toIso8601String(),
      if (clearedBy != null) 'cleared_by': clearedBy,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  LandClearingRecord toDomain() {
    return LandClearingRecord(
      id: id,
      siteId: siteId,
      zoneId: zoneId,
      dailyLogId: dailyLogId,
      planArea: planArea,
      actualArea: actualArea,
      method: method,
      clearingDate: clearingDate,
      clearedBy: clearedBy,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Factory constructor from domain entity.
  factory LandClearingModel.fromDomain(LandClearingRecord entity) {
    return LandClearingModel(
      id: entity.id,
      siteId: entity.siteId,
      zoneId: entity.zoneId,
      dailyLogId: entity.dailyLogId,
      planArea: entity.planArea,
      actualArea: entity.actualArea,
      method: entity.method,
      clearingDate: entity.clearingDate,
      clearedBy: entity.clearedBy,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  /// Converts to core model DTO for Hive storage compatibility.
  LandClearingRecordModel toCoreModel() {
    return LandClearingRecordModel(
      id: id,
      siteId: siteId,
      dailyLogId: dailyLogId,
      zoneId: zoneId,
      planArea: planArea,
      actualArea: actualArea,
      method: method,
      clearedAt: clearingDate,
      clearedBy: clearedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Creates LandClearingModel from core LandClearingRecordModel.
  factory LandClearingModel.fromCoreModel(LandClearingRecordModel core) {
    return LandClearingModel(
      id: core.id,
      siteId: core.siteId,
      zoneId: core.zoneId,
      dailyLogId: core.dailyLogId,
      planArea: core.planArea,
      actualArea: core.actualArea,
      method: core.method,
      clearingDate: core.clearedAt,
      clearedBy: core.clearedBy,
      createdAt: core.createdAt,
      updatedAt: core.updatedAt,
      deletedAt: core.deletedAt,
    );
  }
}
