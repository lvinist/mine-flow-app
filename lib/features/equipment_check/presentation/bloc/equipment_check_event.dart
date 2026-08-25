import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Base class for all equipment check BLoC events.
abstract class EquipmentCheckEvent extends Equatable {
  const EquipmentCheckEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize/load equipment check checklist for given equipment & check type.
class LoadEquipmentCheckEvent extends EquipmentCheckEvent {
  final String siteId;
  final String foremanId;
  final EquipmentType equipmentType;
  final CheckType checkType;
  final String? serialNumber;

  const LoadEquipmentCheckEvent({
    required this.siteId,
    required this.foremanId,
    this.equipmentType = EquipmentType.gnss,
    this.checkType = CheckType.preWork,
    this.serialNumber,
  });

  @override
  List<Object?> get props => [
    siteId,
    foremanId,
    equipmentType,
    checkType,
    serialNumber,
  ];
}

/// Event to load history list of completed equipment checks with optional filters.
class LoadEquipmentHistoryEvent extends EquipmentCheckEvent {
  final String siteId;
  final EquipmentType? equipmentTypeFilter;
  final CheckStatus? statusFilter;
  final String? searchQuery;

  const LoadEquipmentHistoryEvent({
    required this.siteId,
    this.equipmentTypeFilter,
    this.statusFilter,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
    siteId,
    equipmentTypeFilter,
    statusFilter,
    searchQuery,
  ];
}

/// Event to select equipment type (GNSS, Total Station, Drone/UAV).
class SelectEquipmentTypeEvent extends EquipmentCheckEvent {
  final EquipmentType equipmentType;

  const SelectEquipmentTypeEvent(this.equipmentType);

  @override
  List<Object?> get props => [equipmentType];
}

/// Event to select check type (Pre-Work vs Post-Work).
class SelectCheckTypeEvent extends EquipmentCheckEvent {
  final CheckType checkType;

  const SelectCheckTypeEvent(this.checkType);

  @override
  List<Object?> get props => [checkType];
}

/// Event to update serial number.
class UpdateSerialNumberEvent extends EquipmentCheckEvent {
  final String serialNumber;

  const UpdateSerialNumberEvent(this.serialNumber);

  @override
  List<Object?> get props => [serialNumber];
}

/// Event to toggle status of a specific SOP checklist item.
class ToggleCheckItemEvent extends EquipmentCheckEvent {
  final String itemId;
  final bool isPassed;
  final String? remarks;

  const ToggleCheckItemEvent({
    required this.itemId,
    required this.isPassed,
    this.remarks,
  });

  @override
  List<Object?> get props => [itemId, isPassed, remarks];
}

/// Event to update overall inspection remarks/notes.
class UpdateRemarksEvent extends EquipmentCheckEvent {
  final String remarks;

  const UpdateRemarksEvent(this.remarks);

  @override
  List<Object?> get props => [remarks];
}

/// Event to submit the equipment condition check.
class SubmitEquipmentCheckEvent extends EquipmentCheckEvent {
  const SubmitEquipmentCheckEvent();
}
