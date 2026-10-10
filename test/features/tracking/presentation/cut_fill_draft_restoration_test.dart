import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_draft_restoration.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_state.dart';

void main() {
  const siteId = 'site-1';
  const foremanId = 'foreman-1';
  final measurementDate = DateTime(2026, 10, 10);

  group('CutFillDraftRestoration', () {
    test('round-trip equality: encode → decode → fields equal', () {
      final record = CutFillRecord(
        id: 'cf-001',
        siteId: siteId,
        zoneId: 'zone-A',
        bcmVolume: 1500.0,
        lcmVolume: 800.0,
        materialType: 'Soil',
        elevationChange: -2.5,
        measurementDate: measurementDate,
        measuredBy: foremanId,
        notes: 'Test note',
      );

      final state = CutFillFormState(record: record);
      final encoded = CutFillDraftRestoration.encode(state);

      final decoded = CutFillDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.siteId, siteId);
      expect(decoded.foremanId, foremanId);
      expect(decoded.date, measurementDate);
      expect(decoded.zoneId, 'zone-A');
      expect(decoded.bcm, 1500.0);
      expect(decoded.lcm, 800.0);
      expect(decoded.material, 'Soil');
      expect(decoded.elevation, -2.5);
      expect(decoded.notes, 'Test note');
    });

    test('version-mismatch fallback: old version → null', () {
      // Simulate a v2 snapshot (future compatibility)
      const oldSnapshot =
          '{"version":2,"siteId":"site-1","foremanId":"foreman-1",'
          '"date":"2026-10-10","zoneId":"zone-A","bcm":1500.0,'
          '"lcm":800.0,"material":"Soil","elevation":-2.5,"notes":"Test"}';

      final decoded = CutFillDraftRestoration.decode(
        oldSnapshot,
        siteId,
        foremanId,
      );

      expect(decoded, isNull);
    });

    test('version-mismatch fallback: malformed JSON → null', () {
      final decoded = CutFillDraftRestoration.decode(
        'not valid json',
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('siteId mismatch → null', () {
      final record = CutFillRecord(
        id: 'cf-001',
        siteId: siteId,
        zoneId: 'zone-A',
        measurementDate: measurementDate,
        measuredBy: foremanId,
      );
      final encoded = CutFillDraftRestoration.encode(
        CutFillFormState(record: record),
      );

      final decoded = CutFillDraftRestoration.decode(
        encoded,
        'wrong-site',
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('foremanId mismatch → null', () {
      final record = CutFillRecord(
        id: 'cf-001',
        siteId: siteId,
        zoneId: 'zone-A',
        measurementDate: measurementDate,
        measuredBy: foremanId,
      );
      final encoded = CutFillDraftRestoration.encode(
        CutFillFormState(record: record),
      );

      final decoded = CutFillDraftRestoration.decode(
        encoded,
        siteId,
        'wrong-foreman',
      );
      expect(decoded, isNull);
    });

    test('null snapshot → null', () {
      final decoded = CutFillDraftRestoration.decode(null, siteId, foremanId);
      expect(decoded, isNull);
    });

    test('missing required fields → null', () {
      const badSnapshot = '{"version":1,"siteId":"site-1"}';
      final decoded = CutFillDraftRestoration.decode(
        badSnapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('encode omits zero volumes as null', () {
      final record = CutFillRecord(
        id: 'cf-001',
        siteId: siteId,
        zoneId: 'zone-A',
        bcmVolume: 0.0,
        lcmVolume: 0.0,
        materialType: null,
        elevationChange: null,
        measurementDate: measurementDate,
        measuredBy: foremanId,
        notes: null,
      );
      final encoded = CutFillDraftRestoration.encode(
        CutFillFormState(record: record),
      );

      final decoded = CutFillDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.bcm, isNull);
      expect(decoded.lcm, isNull);
      expect(decoded.material, isNull);
      expect(decoded.elevation, isNull);
      expect(decoded.notes, isNull);
    });
  });
}
