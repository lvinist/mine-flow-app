import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';

/// Base class for equipment check BLoC state.
abstract class EquipmentCheckState extends Equatable {
  const EquipmentCheckState();

  @override
  List<Object?> get props => [];
}

/// Initial state before form initialization.
class EquipmentCheckInitial extends EquipmentCheckState {
  const EquipmentCheckInitial();
}

/// Loading state while initializing or preparing SOP checklist.
class EquipmentCheckLoading extends EquipmentCheckState {
  const EquipmentCheckLoading();
}

/// Loaded state containing current SOP form selections and checklist data.
class EquipmentCheckLoaded extends EquipmentCheckState {
  final String siteId;
  final String foremanId;
  final EquipmentType equipmentType;
  final CheckType checkType;
  final String serialNumber;
  final DateTime checkTime;
  final List<CheckItem> checklist;
  final String remarks;
  final bool isSubmitting;
  final String? successMessage;

  const EquipmentCheckLoaded({
    required this.siteId,
    required this.foremanId,
    required this.equipmentType,
    required this.checkType,
    this.serialNumber = '',
    required this.checkTime,
    required this.checklist,
    this.remarks = '',
    this.isSubmitting = false,
    this.successMessage,
  });

  /// Number of passed SOP checklist items.
  int get passedCount =>
      checklist.where((item) => item.isPassed == true).length;

  /// Number of failed SOP checklist items.
  int get failedCount =>
      checklist.where((item) => item.isPassed == false).length;

  /// Number of unanswered SOP checklist items (CF-017).
  int get unansweredCount =>
      checklist.where((item) => item.isPassed == null).length;

  /// Total count of SOP checklist items.
  int get totalCount => checklist.length;

  /// Whether every item has been given an explicit verdict (CF-017 gating).
  bool get isComplete => unansweredCount == 0;

  /// True when every item is answered and none failed.
  bool get isOperational => isComplete && failedCount == 0;

  /// Overall status derived from checklist item results.
  CheckStatus get overallStatus =>
      isOperational ? CheckStatus.passed : CheckStatus.flagged;

  /// Convert current state into domain [EquipmentCheck] entity for persistence.
  EquipmentCheck toEquipmentCheck(String id) {
    return EquipmentCheck(
      id: id,
      siteId: siteId,
      foremanId: foremanId,
      equipmentType: equipmentType,
      serialNumber: serialNumber.isEmpty ? null : serialNumber,
      checkTime: checkTime,
      checkType: checkType,
      status: overallStatus,
      isOperational: isOperational,
      checklist: checklist,
      remarks: remarks.isEmpty ? null : remarks,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  EquipmentCheckLoaded copyWith({
    String? siteId,
    String? foremanId,
    EquipmentType? equipmentType,
    CheckType? checkType,
    String? serialNumber,
    DateTime? checkTime,
    List<CheckItem>? checklist,
    String? remarks,
    bool? isSubmitting,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return EquipmentCheckLoaded(
      siteId: siteId ?? this.siteId,
      foremanId: foremanId ?? this.foremanId,
      equipmentType: equipmentType ?? this.equipmentType,
      checkType: checkType ?? this.checkType,
      serialNumber: serialNumber ?? this.serialNumber,
      checkTime: checkTime ?? this.checkTime,
      checklist: checklist ?? this.checklist,
      remarks: remarks ?? this.remarks,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    siteId,
    foremanId,
    equipmentType,
    checkType,
    serialNumber,
    checkTime,
    checklist,
    remarks,
    isSubmitting,
    successMessage,
  ];
}

/// State indicating equipment check form was successfully submitted.
class EquipmentCheckSubmitted extends EquipmentCheckState {
  final EquipmentCheck check;
  final String message;

  const EquipmentCheckSubmitted({required this.check, required this.message});

  @override
  List<Object?> get props => [check, message];
}

/// State loaded with equipment checks history list.
class EquipmentHistoryLoaded extends EquipmentCheckState {
  final List<EquipmentCheck> checks;
  final EquipmentType? equipmentTypeFilter;
  final CheckStatus? statusFilter;
  final String searchQuery;

  const EquipmentHistoryLoaded({
    required this.checks,
    this.equipmentTypeFilter,
    this.statusFilter,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
    checks,
    equipmentTypeFilter,
    statusFilter,
    searchQuery,
  ];
}

/// Error state when form loading or saving fails.
class EquipmentCheckError extends EquipmentCheckState {
  final String message;

  const EquipmentCheckError(this.message);

  @override
  List<Object?> get props => [message];
}
