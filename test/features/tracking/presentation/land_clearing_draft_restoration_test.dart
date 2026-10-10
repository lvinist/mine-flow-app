import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_draft_restoration.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';

void main() {
  const siteId = 'site-1';
  const foremanId = 'foreman-1';
  final clearingDate = DateTime(2026, 10, 10);

  group('LandClearingDraftRestoration', () {
    test('round-trip equality: encode → decode → fields equal', () {
      final record = LandClearingRecord(
        id: 'lc-001',
        siteId: siteId,
        zoneId: 'zone-B',
        planArea: 15000.0,
        actualArea: 18000.0,
        method: 'Excavator',
        clearingDate: clearingDate,
        clearedBy: foremanId,
        notes: 'Terrain note',
      );

      final state = LandClearingFormState(record: record);
      final encoded = LandClearingDraftRestoration.encodeWithTab(
        state,
        activeTabIndex: 0, // plan tab
      );

      final decoded = LandClearingDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.siteId, siteId);
      expect(decoded.foremanId, foremanId);
      expect(decoded.date, clearingDate);
      expect(decoded.tab, 'plan');
      expect(decoded.zoneId, 'zone-B');
      expect(decoded.method, 'Excavator');
      expect(decoded.plan, 15000.0);
      expect(decoded.actual, 18000.0);
      expect(decoded.notes, 'Terrain note');
      expect(decoded.tabIndex, 0);
    });

    test('round-trip equality: actual tab', () {
      final record = LandClearingRecord(
        id: 'lc-001',
        siteId: siteId,
        zoneId: 'zone-B',
        planArea: 15000.0,
        actualArea: 18000.0,
        method: 'Bulldozer',
        clearingDate: clearingDate,
        clearedBy: foremanId,
      );

      final state = LandClearingFormState(record: record);
      final encoded = LandClearingDraftRestoration.encodeWithTab(
        state,
        activeTabIndex: 1,
      );

      final decoded = LandClearingDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.tab, 'actual');
      expect(decoded.tabIndex, 1);
      expect(decoded.method, 'Bulldozer');
    });

    test('version-mismatch fallback: old version → null', () {
      const oldSnapshot =
          '{"version":2,"siteId":"site-1","foremanId":"foreman-1",'
          '"date":"2026-10-10","tab":"actual","zoneId":"zone-B",'
          '"method":"Excavator","plan":15000.0,"actual":18000.0,"notes":"test"}';

      final decoded = LandClearingDraftRestoration.decode(
        oldSnapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('malformed JSON → null', () {
      final decoded = LandClearingDraftRestoration.decode(
        'not valid json',
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('null snapshot → null', () {
      final decoded = LandClearingDraftRestoration.decode(
        null,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('siteId mismatch → null', () {
      final record = LandClearingRecord(
        id: 'lc-001',
        siteId: siteId,
        zoneId: 'zone-B',
        clearingDate: clearingDate,
        clearedBy: foremanId,
      );
      final encoded = LandClearingDraftRestoration.encode(
        LandClearingFormState(record: record),
      );

      final decoded = LandClearingDraftRestoration.decode(
        encoded,
        'wrong-site',
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('missing required fields → null', () {
      const bad = '{"version":1,"siteId":"site-1"}';
      final decoded = LandClearingDraftRestoration.decode(
        bad,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('invalid tab value → null', () {
      const bad =
          '{"version":1,"siteId":"$siteId","foremanId":"$foremanId",'
          '"date":"2026-10-10","tab":"invalid","zoneId":"zone-B"}';
      final decoded = LandClearingDraftRestoration.decode(
        bad,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });
  });
}
