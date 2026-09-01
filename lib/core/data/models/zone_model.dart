import 'package:mine_flow/core/domain/entities/zone_entity.dart';

/// Data Transfer Object (DTO) for [ZoneEntity] handling JSON serialization
/// to and from Supabase `public.zones` table.
class ZoneModel extends ZoneEntity {
  const ZoneModel({
    required super.id,
    required super.siteId,
    required super.name,
    super.category,
    super.description,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB.
  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      name: json['name'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
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
      'name': name,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  ZoneEntity toDomain() {
    return ZoneEntity(
      id: id,
      siteId: siteId,
      name: name,
      category: category,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  ZoneEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory ZoneModel.fromDomain(ZoneEntity entity) {
    return ZoneModel(
      id: entity.id,
      siteId: entity.siteId,
      name: entity.name,
      category: entity.category,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory ZoneModel.fromEntity(ZoneEntity entity) =>
      ZoneModel.fromDomain(entity);
}
