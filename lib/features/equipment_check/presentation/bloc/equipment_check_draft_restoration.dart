import 'dart:convert';

import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';

/// Restorable snapshot of the equipment check form's editable entry fields only.
///
/// Per 59.0 design §7 (Q2 Option A): only checklist item states + remarks are
/// ENTRY fields for restoration. equipmentType, checkType, serialNumber are UI
/// selection controls — NOT restored (they reload fresh from the checked load).
///
/// CF-017 (STEP-55.7): isPassed MUST stay null until explicitly answered.
/// A null answer must NOT become false on restore — the snapshot preserves
/// the three-state isPassed exactly as entered (true/false/null).
///
/// Snapshot shape (version 1):
/// {
///   version: 1,
///   siteId: string,
///   foremanId: string,
///   checklist: [{ id, isPassed: bool|null, remarks: string|null }],
///   remarks: string?}
class EquipmentCheckDraftRestoration {
  const EquipmentCheckDraftRestoration({
    required this.siteId,
    required this.foremanId,
    required this.checklist,
    required this.remarks,
  });

  // Identity (ENTRY context, not restored record fields)
  final String siteId;
  final String foremanId;

  // ENTRY fields: per-item isPassed (three-state) + per-item remarks + form-level remarks
  final List<CheckItemSnapshot> checklist;
  final String? remarks;

  /// Captures editable checklist states + remarks without persisting success,
  /// errors, sync state, or UI-selection controls (equipmentType/checkType/serialNumber).
  static String encode(EquipmentCheckLoaded state) {
    return jsonEncode({
      'version': 1,
      'siteId': state.siteId,
      'foremanId': state.foremanId,
      'checklist': state.checklist
          .map(
            (item) => {
              'id': item.id,
              'isPassed': item.isPassed,
              'remarks': item.remarks,
            },
          )
          .toList(),
      'remarks': state.remarks,
    });
  }

  /// Strict version-gated decode → null on mismatch (mirrors CutFillDraftRestoration).
  /// Returns null for any malformed or version-mismatched snapshot.
  /// CF-017: isPassed is preserved as true/false/null — a null in the snapshot
  /// stays null (unanswered), never silently coerced to false.
  static EquipmentCheckDraftRestoration? decode(
    String? serialized,
    String expectedSiteId,
    String expectedForemanId,
  ) {
    if (serialized == null) return null;
    try {
      final data = jsonDecode(serialized);
      if (data is! Map<String, dynamic> ||
          data['version'] != 1 ||
          data['siteId'] is! String ||
          data['foremanId'] is! String ||
          data['checklist'] is! List) {
        return null;
      }

      // Identity must match the current form context.
      if (data['siteId'] != expectedSiteId ||
          data['foremanId'] != expectedForemanId) {
        return null;
      }

      final checklistData = data['checklist'] as List;
      final results = <CheckItemSnapshot>[];
      for (final rawItem in checklistData) {
        if (rawItem is! Map<String, dynamic> ||
            rawItem['id'] is! String ||
            rawItem['isPassed'] is! bool?) {
          return null;
        }
        final isPassed = rawItem['isPassed'] as bool?;
        final remarks = rawItem['remarks'];
        if (remarks != null && remarks is! String) return null;
        results.add(
          CheckItemSnapshot(
            id: rawItem['id'] as String,
            isPassed: isPassed,
            remarks: remarks as String?,
          ),
        );
      }

      final formRemarks = data['remarks'];
      if (formRemarks != null && formRemarks is! String) return null;

      return EquipmentCheckDraftRestoration(
        siteId: data['siteId'] as String,
        foremanId: data['foremanId'] as String,
        checklist: results,
        remarks: formRemarks as String?,
      );
    } on FormatException {
      return null;
    }
  }
}

/// One checklist item's restorable snapshot — isPassed is three-state (bool?).
class CheckItemSnapshot {
  final String id;
  final bool? isPassed;
  final String? remarks;

  const CheckItemSnapshot({
    required this.id,
    required this.isPassed,
    this.remarks,
  });

  @override
  String toString() =>
      'CheckItemSnapshot(id: $id, isPassed: $isPassed, remarks: $remarks)';
}

/// Applies a decoded equipment-check snapshot onto a freshly-loaded
/// [EquipmentCheckLoaded] state (reload-before-apply per 59.0 design §2).
/// Matches per-item by stable CheckItem.id; items missing from the fresh
/// checklist are skipped; items absent from snapshot stay unanswered (null).
/// CF-017: isPassed is preserved exactly — null stays null, never false.
EquipmentCheckLoaded applyEquipmentCheckSnapshot(
  EquipmentCheckLoaded freshState,
  EquipmentCheckDraftRestoration snapshot,
) {
  final byId = {for (final item in snapshot.checklist) item.id: item};

  final mergedChecklist = freshState.checklist.map((item) {
    final restored = byId[item.id];
    if (restored == null) return item;
    // CF-017: isPassed null → null (unanswered), NOT false.
    return item.copyWith(
      isPassed: restored.isPassed,
      remarks: restored.remarks ?? item.remarks,
    );
  }).toList();

  return freshState.copyWith(
    checklist: mergedChecklist,
    remarks: snapshot.remarks ?? freshState.remarks,
  );
}
