import 'package:equatable/equatable.dart';

/// Domain entity representing land clearing area measurements (hectares).
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
class LandClearingRecordEntity extends Equatable {
  final String id;
  final String siteId;
  final String? dailyLogId;
  final String zoneId;
  final double areaClearedHa;
  final String? vegetationType;
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
    this.areaClearedHa = 0.0,
    this.vegetationType,
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
        areaClearedHa,
        vegetationType,
        clearedAt,
        clearedBy,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
