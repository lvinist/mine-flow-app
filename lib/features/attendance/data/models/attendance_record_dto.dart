import 'package:mine_flow/features/attendance/domain/entities/attendance_record.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Data Transfer Object (DTO) for [AttendanceRecord] handling JSON serialization
/// to and from Supabase `public.attendance_records` table and Hive local storage.
class AttendanceRecordDto {
  final String id;
  final String siteId;
  final String userId;
  final DateTime date;
  final String status;
  final String? remarks;
  final String? loggedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? userName;

  const AttendanceRecordDto({
    required this.id,
    required this.siteId,
    required this.userId,
    required this.date,
    required this.status,
    this.remarks,
    this.loggedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.userName,
  });

  /// Deserializes JSON map from Supabase or local storage.
  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String;
    return AttendanceRecordDto(
      id: json['id'] as String,
      siteId:
          json['site_id'] as String? ?? 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
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
      userName: json['users']?['name'] as String?,
    );
  }

  /// Serializes DTO into JSON map for Supabase query or local payload.
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

  /// Maps DTO into domain entity [AttendanceRecord].
  AttendanceRecord toDomain() {
    return AttendanceRecord(
      id: id,
      siteId: siteId,
      userId: userId,
      date: date,
      status: AttendanceStatus.fromString(status),
      remarks: remarks,
      loggedBy: loggedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      userName: userName,
    );
  }

  /// Creates DTO from domain entity [AttendanceRecord].
  factory AttendanceRecordDto.fromDomain(AttendanceRecord entity) {
    return AttendanceRecordDto(
      id: entity.id,
      siteId: entity.siteId,
      userId: entity.userId,
      date: entity.date,
      status: entity.status.toValue(),
      remarks: entity.remarks,
      loggedBy: entity.loggedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      userName: entity.userName,
    );
  }
}
