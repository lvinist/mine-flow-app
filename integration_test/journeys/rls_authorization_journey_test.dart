// E2E Critical User Journey: live RLS / authorization (STEP-45.12)
//
// STEP-45 left this file with **zero assertions**. Its only runnable path — the
// single-user case — did nothing but `markTestSkipped`, and its per-role path
// wrapped the one denial check in a `try`/`catch` that did *nothing* when no
// exception was thrown, so an actual RLS hole would have passed silently.
// STEP-48.1 restructured it:
//
//   Part A (per-role matrix, gated on `hasPerRoleAccounts`): supervisor and
//   foreman legs against the policies in
//   supabase/migrations/20260718000002_rls_policies.sql. The crew leg is gated
//   separately on `hasCrewAccount` — STEP-48.0 created `crew@mineflow.dev` in
//   staging but published no `TEST_CREW_*` secrets, so it skips with that named
//   reason instead of pretending to cover crew with another role's session.
//
//   Part B (single authenticated user, unconditional when staging is
//   configured): what one session genuinely proves — that the user's role
//   resolves through `public.current_user_role()`, that role-permitted reads
//   succeed, and that RLS is *enforced* rather than merely enabled, by
//   asserting a write that no policy permits is positively refused.
//
// Denial semantics that shape these assertions: Postgres RLS denies a SELECT by
// filtering rows (empty result), and denies INSERT/UPDATE/DELETE by raising
// SQLSTATE 42501. Only the write path yields an exception, so every "must be
// refused" assertion below is a write, and every read-side restriction is
// asserted as a row-shape property.
//
// Substep 48.12 owns *running* this journey and updating the STEP-44 S0 report's
// deferred live-RLS row with the real result.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/app_harness.dart';
import '../helpers/staging_config.dart';

/// Tables every authenticated role may read (supervisor via `FOR ALL`,
/// foreman/crew via an explicit `FOR SELECT` policy).
const _readableByEveryRole = <String>[
  'zones',
  'equipment_checks',
  'cut_fill_records',
  'land_clearing_records',
  'inventory_items',
  'geospatial_files',
];

/// Asserts that [operation] is refused by row-level security.
///
/// A refusal is a [PostgrestException] carrying SQLSTATE `42501`
/// (`insufficient_privilege`) or a policy-violation message. Asserted
/// positively: if [operation] completes, the test fails, because "no exception
/// was thrown" is exactly how an RLS hole hides.
///
/// [cleanup] runs only in the unexpected-success case, so a probe row that
/// should never have been written does not pollute staging. It is invoked
/// before the failure is raised, and its own errors are swallowed — the
/// security finding is what matters.
Future<void> expectRlsRefusal(
  Future<void> Function() operation, {
  required String reason,
  Future<void> Function()? cleanup,
}) async {
  Object? caught;
  try {
    await operation();
  } catch (error) {
    caught = error;
  }

  if (caught == null) {
    if (cleanup != null) {
      try {
        await cleanup();
      } catch (_) {
        // Best-effort only; the failure below is the real signal.
      }
    }
    fail(
      'RLS did NOT refuse an operation it must refuse — $reason. This is a '
      'security finding, not a test defect: escalate per the STEP-48 PLAN '
      '(security-relevant result → Opus 4.8) before changing this assertion.',
    );
  }

  expect(
    caught,
    isA<PostgrestException>(),
    reason:
        'expected a PostgrestException from the RLS refusal ($reason), got '
        '${caught.runtimeType}: $caught',
  );

  final exception = caught as PostgrestException;
  expect(
    exception.code == '42501' ||
        exception.message.toLowerCase().contains('policy') ||
        exception.message.toLowerCase().contains('row-level security'),
    isTrue,
    reason:
        'the refusal must be an RLS policy denial ($reason), but got '
        'code=${exception.code} message="${exception.message}"',
  );
}

/// Asserts that reading [table] is permitted for the current session.
///
/// A refused read is an exception (transport or policy error); a permitted read
/// returns rows, possibly zero of them. `expect(rows, isA<List>())` would be a
/// tautology, so the evidence here is the *absence* of a throw, made explicit
/// with a failure message that names the table and the policy at stake.
Future<void> expectReadPermitted(
  SupabaseClient client,
  String table, {
  required String role,
}) async {
  try {
    await client.from(table).select().limit(1);
  } catch (error) {
    fail(
      'role "$role" could not read $table, but RLS grants it a SELECT policy '
      '(20260718000002_rls_policies.sql): $error',
    );
  }
}

/// Signs [client] in as [email]/[password], returning the resolved role from
/// `public.users`.
///
/// The self-read is permitted for every role (`supervisor_users_all`, or
/// `users_read_active`'s `id = auth.uid()` branch), so this doubles as proof
/// that `public.current_user_role()` resolves for the session.
Future<String> _signInAndResolveRole(
  SupabaseClient client, {
  required String email,
  required String password,
}) async {
  final response = await client.auth.signInWithPassword(
    email: email,
    password: password,
  );
  final userId = response.user?.id;
  expect(
    userId,
    isNotNull,
    reason: 'sign-in for $email returned no user — check the staging account',
  );

  final row = await client
      .from('users')
      .select('role')
      .eq('id', userId!)
      .single();
  final role = row['role'] as String?;
  expect(
    role,
    isNotNull,
    reason:
        'the authenticated user has no public.users row — RLS role resolution '
        '(public.current_user_role()) cannot work without it',
  );
  return role!;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('RLS Authorization Journey — Part A: per-role matrix (STEP-45.12)', () {
    testWidgets('supervisor and foreman policies behave as documented', (
      tester,
    ) async {
      if (!isStagingConfigured) {
        markTestSkipped(
          'Unverified: staging credentials absent — supply SUPABASE_URL / '
          'SUPABASE_ANON_KEY / TEST_USER_EMAIL / TEST_USER_PASSWORD via '
          '--dart-define.',
        );
        return;
      }
      if (!hasPerRoleAccounts) {
        markTestSkipped(
          'Unverified: per-role staging credentials absent — the RLS matrix '
          'needs TEST_SUPERVISOR_EMAIL, TEST_SUPERVISOR_PASSWORD, '
          'TEST_FOREMAN_EMAIL and TEST_FOREMAN_PASSWORD via --dart-define. '
          'Part B below still verifies enforcement for the single available '
          'session.',
        );
        return;
      }

      await pumpApp(tester);
      final client = Supabase.instance.client;
      await client.auth.signOut();

      // --- Supervisor: FOR ALL on every table ---
      final supervisorRole = await _signInAndResolveRole(
        client,
        email: testSupervisorEmail,
        password: testSupervisorPassword,
      );
      expect(
        supervisorRole,
        'supervisor',
        reason:
            'TEST_SUPERVISOR_* must map to a user whose public.users.role is '
            'supervisor, otherwise this leg tests the wrong policy set',
      );

      for (final table in <String>[
        ...(_readableByEveryRole),
        'attendance_records',
        'daily_logs',
        'users',
      ]) {
        await expectReadPermitted(client, table, role: 'supervisor');
      }

      await client.auth.signOut();

      // --- Foreman: SELECT on zones, but no write path to zones ---
      final foremanRole = await _signInAndResolveRole(
        client,
        email: testForemanEmail,
        password: testForemanPassword,
      );
      expect(
        foremanRole,
        'foreman',
        reason:
            'TEST_FOREMAN_* must map to a user whose public.users.role is '
            'foreman, otherwise this leg tests the wrong policy set',
      );

      for (final table in _readableByEveryRole) {
        await expectReadPermitted(client, table, role: 'foreman');
      }

      // `zones` grants foremen only `zones_read_active` (SELECT). There is no
      // foreman INSERT policy, so this write must be refused. Asserted
      // positively — STEP-45's version logged on success and did nothing when
      // the call did not throw.
      const foremanProbeZone = 'rls-probe-foreman-insert';
      await expectRlsRefusal(
        () async => client.from('zones').insert({'name': foremanProbeZone}),
        reason:
            'a foreman has no INSERT policy on public.zones '
            '(20260718000002_rls_policies.sql §2)',
        cleanup: () async =>
            client.from('zones').delete().eq('name', foremanProbeZone),
      );

      await client.auth.signOut();
    });

    testWidgets('crew policies behave as documented', (tester) async {
      if (!isStagingConfigured) {
        markTestSkipped(
          'Unverified: staging credentials absent — supply SUPABASE_URL / '
          'SUPABASE_ANON_KEY / TEST_USER_EMAIL / TEST_USER_PASSWORD via '
          '--dart-define.',
        );
        return;
      }
      if (!hasCrewAccount) {
        markTestSkipped(
          'Unverified: crew staging credentials absent — STEP-48.0 created the '
          'crew@mineflow.dev account in staging but published no TEST_CREW_* '
          'repository secrets, so the crew leg of the RLS matrix cannot run. '
          'Supply TEST_CREW_EMAIL / TEST_CREW_PASSWORD via --dart-define to '
          'verify. No other role is substituted, because a supervisor or '
          'foreman session would silently invalidate every crew assertion.',
        );
        return;
      }

      await pumpApp(tester);
      final client = Supabase.instance.client;
      await client.auth.signOut();

      final crewRole = await _signInAndResolveRole(
        client,
        email: testCrewEmail,
        password: testCrewPassword,
      );
      expect(crewRole, 'crew');

      for (final table in _readableByEveryRole) {
        await expectReadPermitted(client, table, role: 'crew');
      }

      // `crew_daily_logs_select` restricts crew to approved logs. RLS filters
      // rows rather than raising, so this is asserted on the result shape.
      final crewDailyLogs = await client.from('daily_logs').select('status');
      for (final row in crewDailyLogs) {
        expect(
          row['status'],
          'approved',
          reason:
              'crew_daily_logs_select must expose only approved daily logs; a '
              'non-approved row leaking to crew is an RLS defect',
        );
      }

      // Crew has SELECT on zones and no INSERT policy.
      const crewProbeZone = 'rls-probe-crew-insert';
      await expectRlsRefusal(
        () async => client.from('zones').insert({'name': crewProbeZone}),
        reason: 'crew has no INSERT policy on public.zones',
        cleanup: () async =>
            client.from('zones').delete().eq('name', crewProbeZone),
      );

      await client.auth.signOut();
    });
  });

  group(
    'RLS Authorization Journey — Part B: single-user enforcement (STEP-45.12)',
    () {
      testWidgets(
        'the session role resolves, permitted reads succeed, and an unpermitted '
        'write is positively refused',
        (tester) async {
          if (!isStagingConfigured) {
            markTestSkipped(
              'Unverified: staging credentials absent — supply SUPABASE_URL / '
              'SUPABASE_ANON_KEY / TEST_USER_EMAIL / TEST_USER_PASSWORD via '
              '--dart-define.',
            );
            return;
          }

          await pumpApp(tester);
          final client = Supabase.instance.client;
          await client.auth.signOut();

          // 1. The session's role resolves through the same `public.users` row
          //    `public.current_user_role()` reads. Without this, every policy in
          //    the migration is inert.
          final role = await _signInAndResolveRole(
            client,
            email: testUserEmail,
            password: testUserPassword,
          );
          expect(
            role,
            isIn(<String>['supervisor', 'foreman', 'crew']),
            reason:
                'the role must be one of the three public.user_role values the '
                'policies switch on',
          );

          // 2. Reads this role is entitled to succeed against live staging.
          for (final table in _readableByEveryRole) {
            await expectReadPermitted(client, table, role: role);
          }

          // 3. A write no policy permits for this role is refused.
          //
          //    For foreman/crew that is an INSERT into `zones` (SELECT-only).
          //    A supervisor holds `FOR ALL` on every table, so no table-level
          //    denial exists for it; the unambiguous denial in that case is the
          //    unauthenticated path — every policy is `TO authenticated`, so an
          //    anon INSERT must be refused. That is what distinguishes "RLS is
          //    enforced" from "the tables happen to be open".
          if (role == 'supervisor') {
            await client.auth.signOut();
            const anonProbeZone = 'rls-probe-anon-insert';
            await expectRlsRefusal(
              () async => client.from('zones').insert({'name': anonProbeZone}),
              reason:
                  'every zones policy is TO authenticated, so an anonymous '
                  'INSERT must be refused — the authenticated role under test is '
                  'supervisor (FOR ALL), which has no table-level denial',
              cleanup: () async {
                await client.auth.signInWithPassword(
                  email: testUserEmail,
                  password: testUserPassword,
                );
                await client.from('zones').delete().eq('name', anonProbeZone);
              },
            );
          } else {
            const roleProbeZone = 'rls-probe-single-user-insert';
            await expectRlsRefusal(
              () async => client.from('zones').insert({'name': roleProbeZone}),
              reason:
                  'role "$role" has only a SELECT policy on public.zones, so an '
                  'INSERT must be refused',
              cleanup: () async =>
                  client.from('zones').delete().eq('name', roleProbeZone),
            );
          }

          await client.auth.signOut();
        },
      );
    },
  );
}
