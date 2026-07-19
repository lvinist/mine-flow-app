import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Domain entity representing a digital SOP equipment condition check.
class EquipmentCheck extends Equatable {
  final String id;
  final String siteId;
  final String foremanId;
  final EquipmentType equipmentType;
  final String? serialNumber;
  final DateTime checkTime;
  final CheckType checkType;
  final CheckStatus status;
  final bool isOperational;
  final List<CheckItem> checklist;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const EquipmentCheck({
    required this.id,
    required this.siteId,
    required this.foremanId,
    required this.equipmentType,
    this.serialNumber,
    required this.checkTime,
    required this.checkType,
    required this.status,
    this.isOperational = true,
    this.checklist = const [],
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  EquipmentCheck copyWith({
    String? id,
    String? siteId,
    String? foremanId,
    EquipmentType? equipmentType,
    String? serialNumber,
    DateTime? checkTime,
    CheckType? checkType,
    CheckStatus? status,
    bool? isOperational,
    List<CheckItem>? checklist,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return EquipmentCheck(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      foremanId: foremanId ?? this.foremanId,
      equipmentType: equipmentType ?? this.equipmentType,
      serialNumber: serialNumber ?? this.serialNumber,
      checkTime: checkTime ?? this.checkTime,
      checkType: checkType ?? this.checkType,
      status: status ?? this.status,
      isOperational: isOperational ?? this.isOperational,
      checklist: checklist ?? this.checklist,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        siteId,
        foremanId,
        equipmentType,
        serialNumber,
        checkTime,
        checkType,
        status,
        isOperational,
        checklist,
        remarks,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
