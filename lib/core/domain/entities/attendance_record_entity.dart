import 'package:equatable/equatable.dart';

/// Domain entity representing a daily crew attendance record.
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
class AttendanceRecordEntity extends Equatable {
  final String id;
  final String siteId;
  final String userId;
  final DateTime date;
  final String status; // 'present' | 'absent' | 'sick' | 'leave'
  final String? remarks;
  final String? loggedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const AttendanceRecordEntity({
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
