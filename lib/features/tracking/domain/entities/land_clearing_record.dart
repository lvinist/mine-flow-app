import 'package:equatable/equatable.dart';

/// Domain entity representing land clearing area measurements (in square meters / hectares).
///
/// v2: Replaced generic areaClearedM2 with explicit planArea and actualArea,
/// and renamed clearingMethod to method for consistency.
class LandClearingRecord extends Equatable {
  final String id;
  final String siteId;
  final String zoneId;
  final String? dailyLogId;
  final double planArea;
  final double actualArea;
  final String? method;
  final DateTime clearingDate;
  final String? clearedBy;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const LandClearingRecord({
    required this.id,
    required this.siteId,
    required this.zoneId,
    this.dailyLogId,
    this.planArea = 0.0,
    this.actualArea = 0.0,
    this.method,
    required this.clearingDate,
    this.clearedBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Total cleared area (plan + actual).
  double get totalArea => planArea + actualArea;

  /// Converted total area in Hectares (1 ha = 10,000 m²).
  double get totalAreaHa => totalArea / 10000.0;

  LandClearingRecord copyWith({
    String? id,
    String? siteId,
    String? zoneId,
    String? dailyLogId,
    double? planArea,
    double? actualArea,
    String? method,
    DateTime? clearingDate,
    String? clearedBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return LandClearingRecord(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      dailyLogId: dailyLogId ?? this.dailyLogId,
      planArea: planArea ?? this.planArea,
      actualArea: actualArea ?? this.actualArea,
      method: method ?? this.method,
      clearingDate: clearingDate ?? this.clearingDate,
      clearedBy: clearedBy ?? this.clearedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    siteId,
    zoneId,
    dailyLogId,
    planArea,
    actualArea,
    method,
    clearingDate,
    clearedBy,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
