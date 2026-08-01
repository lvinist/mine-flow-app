import 'package:equatable/equatable.dart';

/// Domain entity representing land clearing area measurements (hectares).
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
/// v2: Replaced generic areaClearedHa with explicit planArea/actualArea
/// and renamed vegetationType to method for clarity.
class LandClearingRecordEntity extends Equatable {
  final String id;
  final String siteId;
  final String? dailyLogId;
  final String zoneId;
  final double planArea;
  final double actualArea;
  final String? method;
  final DateTime clearedAt;
  final String? clearedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const LandClearingRecordEntity({
    required this.id,
    required this.siteId,
    this.dailyLogId,
    required this.zoneId,
    this.planArea = 0.0,
    this.actualArea = 0.0,
    this.method,
    required this.clearedAt,
    this.clearedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
    id,
    siteId,
    dailyLogId,
    zoneId,
    planArea,
    actualArea,
    method,
    clearedAt,
    clearedBy,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
