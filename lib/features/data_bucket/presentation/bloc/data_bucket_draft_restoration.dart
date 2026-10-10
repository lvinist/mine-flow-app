import 'dart:convert';

/// Restorable snapshot of the data-bucket upload form's metadata ENTRY fields
/// only.
///
/// Per 59.0 design §9 (Q2 Option A): only the 3 metadata ENTRY fields are
/// restored — zoneId, acquisitionDate, notes. The file bytes (PlatformFile +
/// Uint8List) are binary/large and explicitly OUT OF SCOPE for snapshot
/// restoration. On restore, the metadata form is pre-filled but the file
/// picker section shows the placeholder + a re-pick banner.
///
/// CONTEXT fields (siteId, fileName, mimeType, fileSize) are reloaded/derived —
/// never snapshotted.
class DataBucketDraftRestoration {
  const DataBucketDraftRestoration({
    required this.siteId,
    required this.zoneId,
    required this.acquisitionDate,
    required this.notes,
  });

  // Identity
  final String siteId;

  // ENTRY metadata fields (3 per 59.0 §9)
  final String? zoneId;
  final DateTime? acquisitionDate;
  final String? notes;

  /// Captures editable metadata values without persisting file bytes,
  /// upload progress, or Drive state.
  static String encode({
    required String siteId,
    required String? zoneId,
    required DateTime? acquisitionDate,
    required String? notes,
  }) {
    return jsonEncode({
      'version': 1,
      'siteId': siteId,
      'zoneId': zoneId,
      'acquisitionDate': acquisitionDate?.toUtc().toIso8601String(),
      'notes': notes,
    });
  }

  /// Strict version-gated decode → null on mismatch (mirrors CutFill pattern).
  /// Returns null for any malformed or version-mismatched snapshot.
  static DataBucketDraftRestoration? decode(
    String? serialized,
    String expectedSiteId,
  ) {
    if (serialized == null) return null;
    try {
      final data = jsonDecode(serialized);
      if (data is! Map<String, dynamic> || data['version'] != 1) return null;

      if (data['siteId'] is! String) return null;

      // Identity must match the current form context.
      if (data['siteId'] != expectedSiteId) return null;

      final zoneId = data['zoneId'];
      if (zoneId != null && zoneId is! String) return null;

      final notes = data['notes'];
      if (notes != null && notes is! String) return null;

      // acquisitionDate: ISO-8601 string or null
      DateTime? acquisitionDate;
      final rawDate = data['acquisitionDate'];
      if (rawDate != null) {
        if (rawDate is! String) return null;
        acquisitionDate = DateTime.tryParse(rawDate);
        // Re-serialize to validate round-trip identity.
        if (acquisitionDate != null &&
            acquisitionDate.toUtc().toIso8601String() != rawDate) {
          return null;
        }
      }

      return DataBucketDraftRestoration(
        siteId: data['siteId'] as String,
        zoneId: zoneId as String?,
        acquisitionDate: acquisitionDate,
        notes: notes as String?,
      );
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
