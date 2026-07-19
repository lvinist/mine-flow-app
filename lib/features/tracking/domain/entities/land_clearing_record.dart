import 'package:equatable/equatable.dart';

/// Domain entity representing land clearing area measurements (in square meters / hectares).
class LandClearingRecord extends Equatable {
  final String id;
  final String siteId;
  final String zoneId;
  final String? dailyLogId;
  final double areaClearedM2;
  final String? clearingMethod;
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
    this.areaClearedM2 = 0.0,
    this.clearingMethod,
    required this.clearingDate,
    this.clearedBy,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Converted cleared area in Hectares (1 ha = 10,000 m²).
  double get areaClearedHa => areaClearedM2 / 10000.0;

  LandClearingRecord copyWith({
    String? id,
    String? siteId,
    String? zoneId,
    String? dailyLogId,
    double? areaClearedM2,
    String? clearingMethod,
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
      areaClearedM2: areaClearedM2 ?? this.areaClearedM2,
      clearingMethod: clearingMethod ?? this.clearingMethod,
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
        areaClearedM2,
        clearingMethod,
        clearingDate,
        clearedBy,
        notes,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
