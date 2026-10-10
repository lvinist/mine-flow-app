import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_draft_restoration.dart';

void main() {
  group('DataBucketDraftRestoration', () {
    test('round-trip equality: encode → decode → fields equal', () {
      final encoded = DataBucketDraftRestoration.encode(
        siteId: 'SITE-01',
        zoneId: 'ZONE-51',
        acquisitionDate: DateTime(2024, 1, 15),
        notes: 'Survey data from drone flight',
      );
      final decoded = DataBucketDraftRestoration.decode(encoded, 'SITE-01');

      expect(decoded, isNotNull);
      expect(decoded!.siteId, 'SITE-01');
      expect(decoded.zoneId, 'ZONE-51');
      expect(decoded.acquisitionDate, DateTime(2024, 1, 15).toUtc());
      expect(decoded.notes, 'Survey data from drone flight');
    });

    test('version-mismatch fallback: old version → null', () {
      const oldSnapshot =
          '{"version":2,"siteId":"SITE-01","zoneId":"ZONE-51","'
          'acquisitionDate":"2024-01-15T00:00:00.000Z","notes":"test"}';
      final decoded = DataBucketDraftRestoration.decode(oldSnapshot, 'SITE-01');
      expect(decoded, isNull);
    });

    test('malformed JSON → null', () {
      final decoded = DataBucketDraftRestoration.decode(
        'not valid json',
        'SITE-01',
      );
      expect(decoded, isNull);
    });

    test('null snapshot → null', () {
      final decoded = DataBucketDraftRestoration.decode(null, 'SITE-01');
      expect(decoded, isNull);
    });

    test('siteId mismatch → null', () {
      final encoded = DataBucketDraftRestoration.encode(
        siteId: 'SITE-01',
        zoneId: 'ZONE-51',
        acquisitionDate: null,
        notes: null,
      );
      final decoded = DataBucketDraftRestoration.decode(encoded, 'SITE-99');
      expect(decoded, isNull);
    });

    test('missing siteId → null', () {
      final decoded = DataBucketDraftRestoration.decode(
        '{"version":1,"zoneId":"ZONE-51","acquisitionDate":null,"notes":"test"}',
        'SITE-01',
      );
      expect(decoded, isNull);
    });

    test('only metadata fields serialized (no file bytes)', () {
      final encoded = DataBucketDraftRestoration.encode(
        siteId: 'SITE-01',
        zoneId: 'ZONE-50',
        acquisitionDate: DateTime(2023, 6, 20),
        notes: 'Test notes',
      );
      // Q2 Option A: file bytes NOT restorable — only metadata serialized.
      expect(encoded, isNot(contains('fileBytes')));
      expect(encoded, isNot(contains('filename')));
      expect(encoded, contains('zoneId'));
      expect(encoded, contains('acquisitionDate'));
      expect(encoded, contains('notes'));
    });

    test('null zoneId/acquisitionDate/notes round-trip', () {
      final encoded = DataBucketDraftRestoration.encode(
        siteId: 'SITE-01',
        zoneId: null,
        acquisitionDate: null,
        notes: null,
      );
      final decoded = DataBucketDraftRestoration.decode(encoded, 'SITE-01');

      expect(decoded, isNotNull);
      expect(decoded!.zoneId, isNull);
      expect(decoded.acquisitionDate, isNull);
      expect(decoded.notes, isNull);
    });
  });
}
