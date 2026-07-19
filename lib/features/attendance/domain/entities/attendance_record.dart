import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';

/// Domain entity representing a crew attendance record.
class AttendanceRecord extends Equatable {
  final String id;
  final String siteId;
  final String userId;
  final DateTime date;
  final AttendanceStatus status;
  final String? remarks;
  final String? loggedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const AttendanceRecord({
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
  });

  AttendanceRecord copyWith({
    String? id,
    String? siteId,
    String? userId,
    DateTime? date,
    AttendanceStatus? status,
    String? remarks,
    String? loggedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      loggedBy: loggedBy ?? this.loggedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        siteId,
        userId,
        date,
        status,
        remarks,
        loggedBy,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
