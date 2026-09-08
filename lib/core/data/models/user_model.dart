import 'package:mine_flow/core/domain/entities/user_entity.dart';

/// Data Transfer Object (DTO) for [UserEntity] handling JSON serialization
/// to and from Supabase `public.users` table.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    required super.siteId,
    super.phone,
    super.nationalId,
    super.birthdate,
    super.gender,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.isActive = true,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB or Edge Function.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: (json['name'] ?? json['full_name'] ?? '') as String,
      role: json['role'] as String,
      siteId:
          json['site_id'] as String? ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
      phone: json['phone'] as String?,
      nationalId: json['national_id'] as String?,
      birthdate: json['birthdate'] != null
          ? DateTime.tryParse(json['birthdate'] as String)
          : null,
      gender: json['gender'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
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
      'email': email,
      'name': name,
      'role': role,
      'site_id': siteId,
      if (phone != null) 'phone': phone,
      if (nationalId != null) 'national_id': nationalId,
      if (birthdate != null)
        'birthdate': birthdate!.toIso8601String().split('T').first,
      if (gender != null) 'gender': gender,
      if (emergencyContactName != null)
        'emergency_contact_name': emergencyContactName,
      if (emergencyContactPhone != null)
        'emergency_contact_phone': emergencyContactPhone,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  UserEntity toDomain() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      role: role,
      siteId: siteId,
      phone: phone,
      nationalId: nationalId,
      birthdate: birthdate,
      gender: gender,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  UserEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory UserModel.fromDomain(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      role: entity.role,
      siteId: entity.siteId,
      phone: entity.phone,
      nationalId: entity.nationalId,
      birthdate: entity.birthdate,
      gender: entity.gender,
      emergencyContactName: entity.emergencyContactName,
      emergencyContactPhone: entity.emergencyContactPhone,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) =>
      UserModel.fromDomain(entity);
}
