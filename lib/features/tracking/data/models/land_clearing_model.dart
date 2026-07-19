import 'package:mine_flow/core/data/models/land_clearing_record_model.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';

/// Data Model / DTO for [LandClearingRecord] extending entity and providing JSON serialization.
class LandClearingModel extends LandClearingRecord {
  const LandClearingModel({
    required super.id,
    required super.siteId,
    required super.zoneId,
    super.dailyLogId,
    super.areaClearedM2 = 0.0,
    super.clearingMethod,
    required super.clearingDate,
    super.clearedBy,
    super.notes,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB or payload.
  factory LandClearingModel.fromJson(Map<String, dynamic> json) {
    final areaM2 = json['area_cleared_m2'] != null
        ? (json['area_cleared_m2'] as num).toDouble()
        : ((json['area_cleared_ha'] as num?)?.toDouble() ?? 0.0) * 10000.0;

    return LandClearingModel(
      id: json['id'] as String,
      siteId: json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      zoneId: json['zone_id'] as String? ?? '',
      dailyLogId: json['daily_log_id'] as String?,
      areaClearedM2: areaM2,
      clearingMethod: (json['clearing_method'] ?? json['vegetation_type']) as String?,
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
      'area_cleared_m2': areaClearedM2,
      'area_cleared_ha': areaClearedHa,
      if (clearingMethod != null) 'clearing_method': clearingMethod,
      if (clearingMethod != null) 'vegetation_type': clearingMethod,
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
      areaClearedM2: areaClearedM2,
      clearingMethod: clearingMethod,
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
      areaClearedM2: entity.areaClearedM2,
      clearingMethod: entity.clearingMethod,
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
      areaClearedHa: areaClearedHa,
      vegetationType: clearingMethod,
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
      areaClearedM2: core.areaClearedHa * 10000.0,
      clearingMethod: core.vegetationType,
      clearingDate: core.clearedAt,
      clearedBy: core.clearedBy,
      createdAt: core.createdAt,
      updatedAt: core.updatedAt,
      deletedAt: core.deletedAt,
    );
  }
}
