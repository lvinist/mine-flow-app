import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/tracking/data/models/inventory_transaction_model.dart';

/// Synthetic ledger row; timestamps intentionally differ across event and audit.
Map<String, dynamic> ledgerRow() => {
  'id': 'transaction-1',
  'site_id': 'site-1',
  'item_id': 'item-1',
  'delta': 2,
  'reason': 'fixture',
  'actor_id': 'actor-1',
  'created_at': '2026-10-06T12:00:00.000Z',
  'occurred_at': '2026-10-01T08:00:00.000Z',
  'created_at_source': 'server',
  'idempotency_key': 'fixture-replay-key',
};

void main() {
  test('unknown timestamp provenance is rejected instead of relabelled', () {
    final input = ledgerRow()..['created_at_source'] = 'unrecognized';
    expect(
      () => InventoryTransactionModel.fromJson(input),
      throwsFormatException,
    );
  });

  test('server provenance cannot invent missing client event time', () {
    final input = ledgerRow()..remove('occurred_at');
    expect(
      () => InventoryTransactionModel.fromJson(input),
      throwsFormatException,
    );
  });

  test(
    'legacy responses preserve original time without claiming a server clock',
    () {
      final input = ledgerRow()
        ..remove('occurred_at')
        ..remove('created_at_source');
      final domain = InventoryTransactionModel.fromJson(input).toDomain();
      final output = InventoryTransactionModel.fromDomain(domain).toJson();
      expect(output['created_at'], input['created_at']);
      expect(output['occurred_at'], input['created_at']);
      expect(output['created_at_source'], 'legacy_client');
      expect(domain.hasServerCreatedAt, isFalse);
    },
  );

  test('event and server audit time survive DTO-domain-DTO round trip', () {
    final input = ledgerRow();
    final domain = InventoryTransactionModel.fromJson(input).toDomain();
    final output = InventoryTransactionModel.fromDomain(domain).toJson();
    expect(output['occurred_at'], input['occurred_at']);
    expect(output['created_at'], input['created_at']);
    expect(output['created_at_source'], 'server');
  });
}
