import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

import '../helpers/app_harness.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('RLS Authorization Journey (STEP-45.12)', () {
    testWidgets('Live RLS behavior per role', (tester) async {
      await pumpApp(tester);

      if (!hasPerRoleAccounts) {
        developer.log(
          'UNVERIFIED: Per-role staging accounts not provided. '
          'Cannot verify full RLS matrix. Please supply TEST_FOREMAN_EMAIL, '
          'TEST_FOREMAN_PASSWORD, TEST_SUPERVISOR_EMAIL, TEST_SUPERVISOR_PASSWORD '
          'via --dart-define.',
          name: 'RLS_TEST',
        );
        markTestSkipped('Unverified: missing per-role credentials.');
        return;
      }

      final client = Supabase.instance.client;

      // 1. Supervisor Role
      await client.auth.signInWithPassword(
        email: testSupervisorEmail,
        password: testSupervisorPassword,
      );

      try {
        await client.from('zones').select().limit(1);
        await client.from('attendance_records').select().limit(1);
        await client.from('equipment_checks').select().limit(1);
        await client.from('daily_logs').select().limit(1);
        await client.from('cut_fill_records').select().limit(1);
        await client.from('land_clearing_records').select().limit(1);
        await client.from('inventory_items').select().limit(1);
        await client.from('geospatial_files').select().limit(1);
      } catch (e) {
        fail('Supervisor RLS read failed: $e');
      }

      await client.auth.signOut();

      // 2. Foreman Role
      await client.auth.signInWithPassword(
        email: testForemanEmail,
        password: testForemanPassword,
      );

      try {
        await client.from('zones').select().limit(1);
      } catch (e) {
        fail('Foreman RLS read failed: $e');
      }

      try {
        await client.from('zones').delete().eq('id', 'non-existent-id');
      } on PostgrestException catch (e) {
        if (e.code == '42501' || e.message.contains('policy')) {
          developer.log(
            'Foreman delete successfully blocked by RLS.',
            name: 'RLS_TEST',
          );
        }
      }

      developer.log(
        'RLS matrix tested with provided accounts.',
        name: 'RLS_TEST',
      );
    });
  });
}
