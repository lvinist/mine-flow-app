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

  print('[OK] Contract verification passed.');
}
