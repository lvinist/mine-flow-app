import 'package:mine_flow/core/data/models/cut_fill_record_model.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';

/// Data Model / DTO for [CutFillRecord] extending entity and providing JSON serialization.
///
/// v2: Maps bcm_volume/lcm_volume instead of cut_volume/fill_volume, and maps material_type.
class CutFillModel extends CutFillRecord {
  const CutFillModel({
    required super.id,
    required super.siteId,
    required super.zoneId,
    super.dailyLogId,
    super.bcmVolume = 0.0,
    super.lcmVolume = 0.0,
    super.materialType,
    super.elevationChange,
    required super.measurementDate,
    super.measuredBy,
    super.notes,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB or payload.
  factory CutFillModel.fromJson(Map<String, dynamic> json) {
    return CutFillModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      zoneId: json['zone_id'] as String? ?? '',
      dailyLogId: json['daily_log_id'] as String?,
      bcmVolume: (json['bcm_volume'] as num?)?.toDouble() ?? 0.0,
      lcmVolume: (json['lcm_volume'] as num?)?.toDouble() ?? 0.0,
      materialType: json['material_type'] as String?,
      elevationChange: (json['elevation_change'] as num?)?.toDouble(),
      measurementDate: json['measured_at'] != null
          ? DateTime.parse(json['measured_at'] as String)
          : (json['measurement_date'] != null
                ? DateTime.parse(json['measurement_date'] as String)
                : DateTime.now()),
      measuredBy: (json['measured_by'] ?? json['created_by']) as String?,
      notes: (json['notes'] ?? json['remarks']) as String?,
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
      'bcm_volume': bcmVolume,
      'lcm_volume': lcmVolume,
      if (materialType != null) 'material_type': materialType,
      if (elevationChange != null) 'elevation_change': elevationChange,
      'measured_at': measurementDate.toIso8601String(),
      if (measuredBy != null) 'measured_by': measuredBy,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  CutFillRecord toDomain() {
    return CutFillRecord(
      id: id,
      siteId: siteId,
      zoneId: zoneId,
      dailyLogId: dailyLogId,
      bcmVolume: bcmVolume,
      lcmVolume: lcmVolume,
      materialType: materialType,
      elevationChange: elevationChange,
      measurementDate: measurementDate,
      measuredBy: measuredBy,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Factory constructor from domain entity.
  factory CutFillModel.fromDomain(CutFillRecord entity) {
    return CutFillModel(
      id: entity.id,
      siteId: entity.siteId,
      zoneId: entity.zoneId,
      dailyLogId: entity.dailyLogId,
      bcmVolume: entity.bcmVolume,
      lcmVolume: entity.lcmVolume,
      materialType: entity.materialType,
      elevationChange: entity.elevationChange,
      measurementDate: entity.measurementDate,
      measuredBy: entity.measuredBy,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  /// Converts to core model DTO for Hive storage compatibility.
  CutFillRecordModel toCoreModel() {
    return CutFillRecordModel(
      id: id,
      siteId: siteId,
      dailyLogId: dailyLogId,
      zoneId: zoneId,
      bcmVolume: bcmVolume,
      lcmVolume: lcmVolume,
      materialType: materialType,
      elevationChange: elevationChange,
      measuredAt: measurementDate,
      measuredBy: measuredBy,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Creates CutFillModel from core CutFillRecordModel.
  factory CutFillModel.fromCoreModel(CutFillRecordModel core) {
    return CutFillModel(
      id: core.id,
      siteId: core.siteId,
      zoneId: core.zoneId,
      dailyLogId: core.dailyLogId,
      bcmVolume: core.bcmVolume,
      lcmVolume: core.lcmVolume,
      materialType: core.materialType,
      elevationChange: core.elevationChange,
      measurementDate: core.measuredAt,
      measuredBy: core.measuredBy,
      notes: core.notes,
      createdAt: core.createdAt,
      updatedAt: core.updatedAt,
      deletedAt: core.deletedAt,
    );
  }
}
