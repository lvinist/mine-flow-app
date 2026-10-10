import 'dart:convert';

import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';

/// Restorable snapshot of the land clearing form's editable entry fields only.
///
/// Context fields (id, siteId, dailyLogId, clearedBy, createdAt, updatedAt,
/// deletedAt) are reloaded from the repository on restore — never snapshotted.
/// Only the 6 ENTRY data fields + tab state are encoded (Step 59.0 design §4):
///   zoneId, method, clearingDate, planArea, actualArea, notes, tab
class LandClearingDraftRestoration {
  const LandClearingDraftRestoration({
    required this.siteId,
    required this.foremanId,
    required this.date,
    required this.tab,
    required this.zoneId,
    required this.method,
    required this.plan,
    required this.actual,
    required this.notes,
  });

  // Identity (ENTRY context, not restored record fields)
  final String siteId;
  final String foremanId;
  final DateTime date;

  // Tab state — UI selection, must be preserved per 59.0 design §4
  final String tab;

  // ENTRY data fields
  final String zoneId;
  final String? method;
  final double? plan;
  final double? actual;
  final String? notes;

  /// Captures editable values without persisting success, errors, or sync state.
  static String encode(LandClearingFormState state) {
    final record = state.record;
    return jsonEncode({
      'version': 1,
      'siteId': record.siteId,
      'foremanId': record.clearedBy ?? '',
      'date': record.clearingDate.toIso8601String().substring(0, 10),
      'tab': 'actual', // default; view-level tab state set separately
      'zoneId': record.zoneId,
      'method': record.method,
      'plan': record.planArea == 0.0 ? null : record.planArea,
      'actual': record.actualArea == 0.0 ? null : record.actualArea,
      'notes': record.notes,
    });
  }

  /// Overload that captures the active tab from the view controller.
  static String encodeWithTab(
    LandClearingFormState state, {
    required int activeTabIndex,
  }) {
    final data = jsonDecode(encode(state)) as Map<String, dynamic>;
    data['tab'] = activeTabIndex == 0 ? 'plan' : 'actual';
    return jsonEncode(data);
  }

  /// Rejects malformed or incompatible data rather than manufacturing a draft.
  static LandClearingDraftRestoration? decode(
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
          data['date'] is! String ||
          data['tab'] is! String ||
          data['zoneId'] is! String) {
        return null;
      }

      // Identity must match the current form context.
      if (data['siteId'] != expectedSiteId ||
          data['foremanId'] != expectedForemanId) {
        return null;
      }

      final dateText = data['date'] as String;
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateText)) return null;
      final date = DateTime.tryParse(dateText);
      if (date == null || date.toIso8601String().substring(0, 10) != dateText) {
        return null;
      }

      final tab = data['tab'] as String;
      if (tab != 'plan' && tab != 'actual') return null;

      final plan = _decodeDouble(data['plan']);
      final actual = _decodeDouble(data['actual']);

      final method = data['method'];
      if (method != null && method is! String) return null;

      final notes = data['notes'];
      if (notes != null && notes is! String) return null;

      return LandClearingDraftRestoration(
        siteId: data['siteId'] as String,
        foremanId: data['foremanId'] as String,
        date: date,
        tab: tab,
        zoneId: data['zoneId'] as String,
        method: method as String?,
        plan: plan,
        actual: actual,
        notes: notes as String?,
      );
    } on FormatException {
      return null;
    }
  }

  static double? _decodeDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool get isPlanTab => tab == 'plan';
  int get tabIndex => isPlanTab ? 0 : 1;
}
