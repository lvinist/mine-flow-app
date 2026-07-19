import 'package:mine_flow/core/domain/entities/attendance_record_entity.dart';

/// Data Transfer Object (DTO) for [AttendanceRecordEntity] handling JSON serialization
/// to and from Supabase `public.attendance_records` table.
class AttendanceRecordModel extends AttendanceRecordEntity {
  const AttendanceRecordModel({
    required super.id,
    required super.siteId,
    required super.userId,
    required super.date,
    required super.status,
    super.remarks,
    super.loggedBy,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Factory constructor to deserialize JSON from Supabase DB.
  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String;
    return AttendanceRecordModel(
      id: json['id'] as String,
      siteId: json['site_id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      userId: json['user_id'] as String,
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      status: json['status'] as String? ?? 'present',
      remarks: json['remarks'] as String?,
      loggedBy: json['logged_by'] as String?,
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
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'status': status,
      if (remarks != null) 'remarks': remarks,
      if (loggedBy != null) 'logged_by': loggedBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  /// Converts this model instance into a pure domain entity.
  AttendanceRecordEntity toDomain() {
    return AttendanceRecordEntity(
      id: id,
      siteId: siteId,
      userId: userId,
      date: date,
      status: status,
      remarks: remarks,
      loggedBy: loggedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  AttendanceRecordEntity toEntity() => toDomain();

  /// Factory constructor from a domain entity.
  factory AttendanceRecordModel.fromDomain(AttendanceRecordEntity entity) {
    return AttendanceRecordModel(
      id: entity.id,
      siteId: entity.siteId,
      userId: entity.userId,
      date: entity.date,
      status: entity.status,
      remarks: entity.remarks,
      loggedBy: entity.loggedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  factory AttendanceRecordModel.fromEntity(AttendanceRecordEntity entity) =>
      AttendanceRecordModel.fromDomain(entity);
}
