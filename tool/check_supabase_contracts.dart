// ignore_for_file: avoid_print
//
// Supabase contract staleness guard.
//
// The contract artifact is `supabase/types/database.ts` — real TypeScript
// types emitted by `supabase gen types --lang typescript --linked`. Dart
// output was removed from the Supabase CLI ecosystem (see supabase/cli#6230;
// the official `supabase_typegen` package is still a placeholder), so the TS
// schema dump is the committed source of truth for the DB contract.
//
// Checks:
//   1. Artifact exists and looks like genuine typegen output (stub rejection).
//   2. Locally: uncommitted migrations must come with an updated artifact.
//   3. In CI: migrations changed vs base ref must come with an updated artifact.
//   4. Targeted column/table presence: committed-but-stale artifact regressions
//      that the commit-pairing check above cannot catch.
import 'dart:io';

void main() {
  const artifactPath = 'supabase/types/database.ts';
  const migrationsDirPath = 'supabase/migrations';
  final artifact = File(artifactPath);

  print('Supabase Contract Check');
  print('-----------------------');
  print('Contract artifact: $artifactPath');
  print('Regeneration Command:');
  print('  supabase gen types --lang typescript --linked > $artifactPath\n');

  if (!artifact.existsSync()) {
    print('[ERROR] The contract artifact ($artifactPath) does not exist.');
    exit(1);
  }

  // Stub rejection: real typegen output contains the Database type and at
  // least one table definition. A placeholder/stub file must fail the gate.
  final content = artifact.readAsStringSync();
  if (!content.contains('export type Database') ||
      !content.contains('__InternalSupabase')) {
    print(
      '[ERROR] $artifactPath does not look like `supabase gen types` output '
      '(missing "export type Database").',
    );
    print('Regenerate it; do not hand-write or stub this file.');
    exit(1);
  }
  if (content.length < 2000) {
    print(
      '[ERROR] $artifactPath is suspiciously small '
      '(${content.length} bytes) for this schema.',
    );
    print('Regenerate it with `supabase gen types --lang typescript`.');
    exit(1);
  }

  // Detect uncommitted/staged changes first (for local)
  final statusResult = Process.runSync('git', ['status', '--porcelain']);
  final statusOutput = statusResult.stdout.toString();

  bool migUncommitted = false;
  bool typeUncommitted = false;

  for (var line in statusOutput.split('\n')) {
    // Porcelain v1 format: "XY path"
    // XY = 2-char status code, index 2 = space, path starts at index 3.
    // Skip blank lines (trailing newline or empty output).
    if (line.length < 4) continue;
    final path = line.substring(3).trim().replaceAll('\\', '/');
    if (path.startsWith(migrationsDirPath)) migUncommitted = true;
    if (path.startsWith(artifactPath)) typeUncommitted = true;
  }

  if (migUncommitted && !typeUncommitted) {
    print(
      '[ERROR] Uncommitted database migrations found, but $artifactPath is not updated.',
    );
    print('Please regenerate the types before committing.');
    exit(1);
  }

  // In CI, checking diff against BASE_REF
  final isCi = Platform.environment['CI'] == 'true';
  if (isCi) {
    final baseRef = Platform.environment['GITHUB_BASE_REF'];
    final base = (baseRef != null && baseRef.isNotEmpty)
        ? 'origin/$baseRef'
        : 'HEAD^';

    if (baseRef != null && baseRef.isNotEmpty) {
      Process.runSync('git', ['fetch', 'origin', baseRef, '--depth=1']);
    } else {
      Process.runSync('git', ['fetch', '--depth=2']); // Ensure HEAD^ exists
    }

    final diffResult = Process.runSync('git', [
      'diff',
      '--name-only',
      base,
      'HEAD',
    ]);
    final diffOutput = diffResult.stdout.toString();

    bool migChanged = false;
    bool typeChanged = false;
    for (var line in diffOutput.split('\n')) {
      final path = line.replaceAll('\\', '/');
      if (path.startsWith(migrationsDirPath)) migChanged = true;
      if (path.startsWith(artifactPath)) typeChanged = true;
    }

    if (migChanged && !typeChanged) {
      print(
        '[ERROR] Migrations modified in this PR/push, but $artifactPath was not updated.',
      );
      print('You must regenerate the types when modifying the schema.');
      exit(1);
    }
  }

  // ---------------------------------------------------------------------------
  // Targeted staleness regression (2026-09-21 STEP-55.6 hazard-drift, and the
  // 2026-09-23 STEP-55.8 inventory-transaction ledger gap).
  //
  // The commit-pairing checks above cannot detect an artifact that is committed
  // *alongside* a migration yet silently omits that migration's new columns or
  // tables. On 2026-09-21 the STEP-55.6 hazard/approval migration
  // (20260912000001_step_55_6_daily_log_hazard_contract.sql) had been committed
  // since 2026-09-13, but supabase/types/database.ts still listed only the 13
  // pre-hazard daily_logs columns — the four hazard columns were absent, and the
  // migration had never been applied to the live database. This gate passed
  // anyway. The same class of gap recurred in STEP-55.8: the
  // 20260913000001_step_55_8_inventory_transactions.sql migration (committed in
  // 16e31bd) introduces the `inventory_transactions` ledger table, but
  // database.ts (last regenerated in dea0f30, STEP-55.6) omits it.
  //
  // Scope note: these are targeted regression checks for the exact columns and
  // tables that have drifted, NOT a general migration/artifact schema-diff. A
  // general ADD COLUMN / CREATE TABLE presence scan was considered and rejected:
  // it false-fires on a migration that is committed but legitimately not yet
  // applied to the linked database (e.g. a sibling lane's unapplied migration),
  // which would turn this shared contract gate red on work this lane does not
  // own. Keep it mechanical and specific; extend the lists below if a future
  // incident proves another column or table silently dropped.
  const requiredColumns = <String>[
    'hazard_state',
    'hazard_severity',
    'hazard_notes',
    'hazard_action',
  ];
  final absentColumns = requiredColumns
      .where((col) => !RegExp('\\b$col\\b').hasMatch(content))
      .toList();
  if (absentColumns.isNotEmpty) {
    print(
      '[ERROR] $artifactPath is stale: the STEP-55.6 daily_logs hazard columns '
      'are absent from the artifact: ${absentColumns.join(', ')}.',
    );
    print(
      'These columns are added by '
      '20260912000001_step_55_6_daily_log_hazard_contract.sql. Regenerate the '
      'artifact after the migration is applied to the linked database:',
    );
    print(
      '\n  supabase db push --linked   # apply the migration if not yet applied\n'
      '  supabase gen types --lang typescript --linked > $artifactPath',
    );
    print('See the 2026-09-21 STEP-55.6 hazard-drift incident.');
    exit(1);
  }

  // For tables, a bare word match is not enough: the token
  // `inventory_transactions` also appears as a foreign-key reference inside the
  // `inventory_items` Insert/Row block. We anchor on the table-definition shape
  // `<table>: {\n      //   Row: {` — the typegen emission for a table in the
  // public schema — which is specific to a real table definition.
  const requiredTables = <String>['inventory_transactions'];
  final missingTables = requiredTables
      .where(
        (tbl) => !RegExp(
          "$tbl: \\{\\s*\\n\\s*Row: \\{",
          dotAll: true,
        ).hasMatch(content),
      )
      .toList();
  if (missingTables.isNotEmpty) {
    print(
      '[ERROR] $artifactPath is stale: the STEP-55.8 inventory_transactions '
      'table definition is absent from the artifact: '
      '${missingTables.join(', ')}.',
    );
    print(
      'This table is added by '
      '20260913000001_step_55_8_inventory_transactions.sql. '
      'Regenerate the artifact after that migration is applied to the '
      'linked database:',
    );
    print(
      '\n  supabase db push --linked   # apply the migration if not yet applied\n'
      '  supabase gen types --lang typescript --linked > $artifactPath',
    );
    print(
      'See the 2026-09-23 STEP-55.8 residual findings (database.ts staleness).',
    );
    exit(1);
  }

  print('[OK] Contract verification passed.');
}
