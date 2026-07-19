import 'package:equatable/equatable.dart';

/// Domain entity representing pre/post-work survey equipment condition checks.
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
class EquipmentCheckEntity extends Equatable {
  final String id;
  final String siteId;
  final String foremanId;
  final String equipmentType; // 'gnss' | 'total_station' | 'drone'
  final String? serialNumber;
  final DateTime checkTime;
  final String checkType; // 'pre_work' | 'post_work'
  final bool isOperational;
  final Map<String, dynamic> checklistData;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const EquipmentCheckEntity({
    required this.id,
    required this.siteId,
    required this.foremanId,
    required this.equipmentType,
    this.serialNumber,
    required this.checkTime,
    this.checkType = 'pre_work',
    this.isOperational = true,
    this.checklistData = const {},
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        siteId,
        foremanId,
        equipmentType,
        serialNumber,
        checkTime,
        checkType,
        isOperational,
        checklistData,
        remarks,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
