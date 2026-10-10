import 'dart:convert';

import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_state.dart';

/// Restorable snapshot of the cut/fill form's editable entry fields only.
///
/// Context fields (id, siteId, dailyLogId, measurementDate, measuredBy,
/// createdAt, updatedAt) are reloaded from the repository on restore — never
/// snapshotted.  Only the 6 ENTRY fields are encoded (Step 59.0 design §3):
///   zoneId, bcmVolume, lcmVolume, materialType, elevationChange, notes
class CutFillDraftRestoration {
  const CutFillDraftRestoration({
    required this.siteId,
    required this.foremanId,
    required this.date,
    required this.zoneId,
    required this.bcm,
    required this.lcm,
    required this.material,
    required this.elevation,
    required this.notes,
  });

  // Identity (ENTRY context, not restored record fields)
  final String siteId;
  final String foremanId;
  final DateTime date;

  // ENTRY fields
  final String zoneId;
  final double? bcm;
  final double? lcm;
  final String? material;
  final double? elevation;
  final String? notes;

  /// Captures editable values without persisting success, errors, or sync state.
  static String encode(CutFillFormState state) {
    final record = state.record;
    return jsonEncode({
      'version': 1,
      'siteId': record.siteId,
      'foremanId': record.measuredBy ?? '',
      'date': record.measurementDate.toIso8601String().substring(0, 10),
      'zoneId': record.zoneId,
      'bcm': record.bcmVolume == 0.0 ? null : record.bcmVolume,
      'lcm': record.lcmVolume == 0.0 ? null : record.lcmVolume,
      'material': record.materialType,
      'elevation': record.elevationChange,
      'notes': record.notes,
    });
  }

  /// Rejects malformed or incompatible data rather than manufacturing a draft.
  static CutFillDraftRestoration? decode(
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

      final bcm = _decodeDouble(data['bcm']);
      final lcm = _decodeDouble(data['lcm']);
      final elevation = _decodeDouble(data['elevation']);

      final material = data['material'];
      if (material != null && material is! String) return null;

      final notes = data['notes'];
      if (notes != null && notes is! String) return null;

      return CutFillDraftRestoration(
        siteId: data['siteId'] as String,
        foremanId: data['foremanId'] as String,
        date: date,
        zoneId: data['zoneId'] as String,
        bcm: bcm,
        lcm: lcm,
        material: material as String?,
        elevation: elevation,
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
}
