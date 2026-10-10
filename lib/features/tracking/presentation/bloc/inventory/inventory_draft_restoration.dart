import 'dart:convert';

import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';

/// Restorable snapshot of the inventory form's editable ENTRY fields only.
///
/// Per 59.0 design §8: CONTEXT fields (id, siteId, createdAt, updatedAt,
/// deletedAt) are reloaded from the repository on restore — never snapshotted.
/// zoneId is borderline (treated as ENTRY identity per 59.0 disposition).
///
/// The 7 ENTRY fields:
///   itemName, category, quantityOnHand, unit, minThreshold, sku, notes
class InventoryDraftRestoration {
  const InventoryDraftRestoration({
    required this.siteId,
    required this.zoneId,
    required this.itemName,
    required this.category,
    required this.quantityOnHand,
    required this.unit,
    required this.minThreshold,
    required this.sku,
    required this.notes,
  });

  // Identity (ENTRY context, not restored record fields)
  final String siteId;
  final String? zoneId;

  // ENTRY fields (7 per 59.0 §8)
  final String itemName;
  final String? category;
  final double quantityOnHand;
  final String unit;
  final double? minThreshold;
  final String? sku;
  final String? notes;

  /// Captures editable values without persisting success, errors, or sync state.
  static String encode(InventoryFormState state) {
    final item = state.item;
    return jsonEncode({
      'version': 1,
      'siteId': item.siteId,
      'zoneId': item.zoneId,
      'itemName': item.itemName,
      'category': item.category,
      'quantityOnHand': item.quantityOnHand,
      'unit': item.unit,
      'minThreshold': item.minThreshold,
      'sku': item.sku,
      'notes': item.notes,
    });
  }

  /// Strict version-gated decode → null on mismatch (mirrors CutFill pattern).
  /// Returns null for any malformed or version-mismatched snapshot.
  static InventoryDraftRestoration? decode(
    String? serialized,
    String expectedSiteId,
  ) {
    if (serialized == null) return null;
    try {
      final data = jsonDecode(serialized);
      if (data is! Map<String, dynamic> ||
          data['version'] != 1 ||
          data['siteId'] is! String ||
          data['itemName'] is! String ||
          data['quantityOnHand'] is! num ||
          data['unit'] is! String) {
        return null;
      }

      // Identity must match the current form context.
      if (data['siteId'] != expectedSiteId) return null;

      final category = data['category'];
      if (category != null && category is! String) return null;

      final sku = data['sku'];
      if (sku != null && sku is! String) return null;

      final notes = data['notes'];
      if (notes != null && notes is! String) return null;

      final minThreshold = _decodeDouble(data['minThreshold']);

      return InventoryDraftRestoration(
        siteId: data['siteId'] as String,
        zoneId: data['zoneId'] as String?,
        itemName: data['itemName'] as String,
        category: category as String?,
        quantityOnHand: (data['quantityOnHand'] as num).toDouble(),
        unit: data['unit'] as String,
        minThreshold: minThreshold,
        sku: sku as String?,
        notes: notes as String?,
      );
    } on FormatException {
      return null;
    } catch (_) {
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
