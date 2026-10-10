import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_draft_restoration.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';

void main() {
  const siteId = 'site-eq-1';
  const foremanId = 'foreman-eq-1';

  EquipmentCheckLoaded _makeLoaded({
    String serial = 'SN-001',
    List<CheckItem>? checklist,
    String remarks = '',
  }) {
    return EquipmentCheckLoaded(
      siteId: siteId,
      foremanId: foremanId,
      equipmentType: EquipmentType.gnss,
      checkType: CheckType.preWork,
      serialNumber: serial,
      checkTime: DateTime(2026, 10, 10),
      checklist:
          checklist ??
          [
            const CheckItem(id: 'item-1', label: 'Battery', isPassed: null),
            const CheckItem(id: 'item-2', label: 'Fuel', isPassed: null),
          ],
      remarks: remarks,
    );
  }

  group('EquipmentCheckDraftRestoration', () {
    test('round-trip equality: encode → decode → fields equal', () {
      final state = _makeLoaded(
        checklist: [
          const CheckItem(id: 'item-1', label: 'Battery', isPassed: true),
          const CheckItem(id: 'item-2', label: 'Fuel', isPassed: false),
        ],
        remarks: 'All good',
      );

      final encoded = EquipmentCheckDraftRestoration.encode(state);
      final decoded = EquipmentCheckDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.siteId, siteId);
      expect(decoded.foremanId, foremanId);
      expect(decoded.checklist, hasLength(2));

      // item-1: pass + no remarks override (stays empty)
      expect(decoded.checklist[0].isPassed, isTrue);
      // item-2: fail + form-level remarks (not per-item)
      expect(decoded.checklist[1].isPassed, isFalse);
      expect(decoded.remarks, 'All good');
    });

    test('round-trip with per-item remarks', () {
      final state = _makeLoaded(
        checklist: [
          const CheckItem(
            id: 'item-1',
            label: 'Battery',
            isPassed: true,
            remarks: '12.6V',
          ),
          const CheckItem(
            id: 'item-2',
            label: 'Fuel',
            isPassed: false,
            remarks: 'Low on diesel',
          ),
        ],
        remarks: 'Fuel low',
      );

      final encoded = EquipmentCheckDraftRestoration.encode(state);
      final decoded = EquipmentCheckDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.checklist[0].remarks, '12.6V');
      expect(decoded.checklist[1].remarks, 'Low on diesel');
      expect(decoded.remarks, 'Fuel low');
    });

    test('version-mismatch fallback: v2 snapshot → null', () {
      final snapshot =
          '{"version":2,"siteId":"$siteId","foremanId":"$foremanId",'
          '"checklist":[],"remarks":""}';

      final decoded = EquipmentCheckDraftRestoration.decode(
        snapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('null snapshot → null', () {
      final decoded = EquipmentCheckDraftRestoration.decode(
        null,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('malformed JSON → null', () {
      final decoded = EquipmentCheckDraftRestoration.decode(
        'not json',
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('siteId mismatch → null', () {
      final state = _makeLoaded();
      final encoded = EquipmentCheckDraftRestoration.encode(state);

      final decoded = EquipmentCheckDraftRestoration.decode(
        encoded,
        'wrong-site',
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('foremanId mismatch → null', () {
      final state = _makeLoaded();
      final encoded = EquipmentCheckDraftRestoration.encode(state);

      final decoded = EquipmentCheckDraftRestoration.decode(
        encoded,
        siteId,
        'wrong-foreman',
      );
      expect(decoded, isNull);
    });

    test('CF-017 null-preservation: unanswered item stays null, not false', () {
      // A fresh form has isPassed = null for all items. After encode → decode,
      // null must remain null (unanswered), never silently coerced to false.
      final state = _makeLoaded();

      final encoded = EquipmentCheckDraftRestoration.encode(state);
      final decoded = EquipmentCheckDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      for (final item in decoded!.checklist) {
        expect(item.isPassed, isNull);
      }
    });

    test('CF-017 mixed states preserved exactly', () {
      final state = _makeLoaded(
        checklist: [
          const CheckItem(id: 'item-1', label: 'Battery', isPassed: null),
          const CheckItem(id: 'item-2', label: 'Fuel', isPassed: true),
          const CheckItem(id: 'item-3', label: 'Oil', isPassed: false),
        ],
      );

      final encoded = EquipmentCheckDraftRestoration.encode(state);
      final decoded = EquipmentCheckDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      final items = {for (final c in decoded!.checklist) c.id: c};
      expect(items['item-1']!.isPassed, isNull);
      expect(items['item-2']!.isPassed, isTrue);
      expect(items['item-3']!.isPassed, isFalse);
    });

    test('explicit bool false preserved (not coerced to null)', () {
      final state = _makeLoaded(
        checklist: [
          const CheckItem(id: 'item-1', label: 'Battery', isPassed: false),
        ],
      );

      final encoded = EquipmentCheckDraftRestoration.encode(state);
      final decoded = EquipmentCheckDraftRestoration.decode(
        encoded,
        siteId,
        foremanId,
      );

      expect(decoded, isNotNull);
      expect(decoded!.checklist[0].isPassed, isFalse);
    });

    test('missing checklist field → null', () {
      final badSnapshot = jsonEncode({
        'version': 1,
        'siteId': siteId,
        'foremanId': foremanId,
      });
      final decoded = EquipmentCheckDraftRestoration.decode(
        badSnapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('checklist item with wrong isPassed type → null', () {
      final badSnapshot = jsonEncode({
        'version': 1,
        'siteId': siteId,
        'foremanId': foremanId,
        'checklist': [
          {'id': 'item-1', 'isPassed': 'yes', 'remarks': null},
        ],
        'remarks': '',
      });
      final decoded = EquipmentCheckDraftRestoration.decode(
        badSnapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });

    test('missing item id → null', () {
      final badSnapshot = jsonEncode({
        'version': 1,
        'siteId': siteId,
        'foremanId': foremanId,
        'checklist': [
          {'isPassed': true, 'remarks': null},
        ],
        'remarks': '',
      });
      final decoded = EquipmentCheckDraftRestoration.decode(
        badSnapshot,
        siteId,
        foremanId,
      );
      expect(decoded, isNull);
    });
  });

  group('applyEquipmentCheckSnapshot', () {
    test(
      'applies isPassed + remarks onto fresh checklist, preserves unmatched',
      () {
        final fresh = _makeLoaded(
          checklist: [
            const CheckItem(id: 'item-1', label: 'Battery', isPassed: null),
            const CheckItem(id: 'item-2', label: 'Fuel', isPassed: null),
            const CheckItem(id: 'item-3', label: 'Oil', isPassed: null),
          ],
          serial: 'SN-FRESH',
          remarks: '',
        );

        final snapshot = EquipmentCheckDraftRestoration(
          siteId: siteId,
          foremanId: foremanId,
          checklist: [
            const CheckItemSnapshot(id: 'item-1', isPassed: true),
            const CheckItemSnapshot(
              id: 'item-2',
              isPassed: false,
              remarks: 'Leaky',
            ),
          ],
          remarks: 'Form-level remarks',
        );

        final restored = applyEquipmentCheckSnapshot(fresh, snapshot);

        // item-1: pass + no remarks override (stays empty)
        expect(restored.checklist[0].isPassed, isTrue);
        // item-2: fail + remarks restored from snapshot
        expect(restored.checklist[1].isPassed, isFalse);
        expect(restored.checklist[1].remarks, 'Leaky');
        // item-3: absent from snapshot, stays unanswered (null)
        expect(restored.checklist[2].isPassed, isNull);
        // Form-level remarks from snapshot
        expect(restored.remarks, 'Form-level remarks');

        // CONTEXT fields preserved from fresh load (NOT restored):
        expect(restored.serialNumber, 'SN-FRESH');
        expect(restored.equipmentType, EquipmentType.gnss);
        expect(restored.checkType, CheckType.preWork);
        expect(restored.checkTime, DateTime(2026, 10, 10));
      },
    );

    test('snapshot item absent from fresh checklist is skipped', () {
      final fresh = _makeLoaded(
        checklist: [
          const CheckItem(id: 'item-1', label: 'Battery', isPassed: null),
        ],
      );

      final snapshot = EquipmentCheckDraftRestoration(
        siteId: siteId,
        foremanId: foremanId,
        checklist: [
          const CheckItemSnapshot(id: 'item-1', isPassed: true),
          const CheckItemSnapshot(id: 'item-gone', isPassed: false),
        ],
        remarks: 'remarks',
      );

      final restored = applyEquipmentCheckSnapshot(fresh, snapshot);
      expect(restored.checklist, hasLength(1));
      expect(restored.checklist[0].isPassed, isTrue);
    });

    test('CF-017: null isPassed stays null after apply', () {
      final fresh = _makeLoaded(
        checklist: [
          const CheckItem(id: 'item-1', label: 'Battery', isPassed: null),
        ],
      );

      final snapshot = EquipmentCheckDraftRestoration(
        siteId: siteId,
        foremanId: foremanId,
        checklist: [const CheckItemSnapshot(id: 'item-1', isPassed: null)],
        remarks: 'remarks',
      );

      final restored = applyEquipmentCheckSnapshot(fresh, snapshot);
      expect(restored.checklist[0].isPassed, isNull);
    });
  });
}
