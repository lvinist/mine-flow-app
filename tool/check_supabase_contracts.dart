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
import 'dart:convert';
import 'dart:io';

const _artifactPath = 'supabase/types/database.ts';
const _receiptPath = 'supabase/types/no_shape_change.json';

/// Fails closed on missing evidence, malformed receipts and failed Git commands.
void main() {
  try {
    _check();
  } catch (error) {
    print('[ERROR] Contract verification failed: $error');
    exitCode = 1;
  }
}

/// Checks the generated artifact and each applicable migration change range.
void _check() {
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

  _validateArtifact(artifact.readAsStringSync());

  // The index is a separate deliverable: unstaged fixes cannot bless it.
  _checkBatch(
    _paths(
      _git([
        'diff',
        '--cached',
        '--no-renames',
        '--name-only',
        '-z',
        'HEAD',
        '--',
      ]),
    ),
    'HEAD',
    '',
  );
  // NUL-delimited Git output keeps unusual filenames from hiding migrations.
  final localPaths =
      _paths(_git(['diff', '--no-renames', '--name-only', '-z', 'HEAD', '--']))
        ..addAll(
          _paths(_git(['ls-files', '--others', '-z', '--', migrationsDirPath])),
        );
  _checkBatch(localPaths, 'HEAD', null);

  if (Platform.environment['CI'] == 'true') {
    final commit = _ciBase();
    _checkBatch(
      _paths(
        _git([
          'diff',
          '--no-renames',
          '--name-only',
          '-z',
          commit,
          'HEAD',
          '--',
        ]),
      ),
      commit,
      'HEAD',
    );
  }

  print('[OK] Contract verification passed.');
}

/// Validates every checked snapshot, not just a potentially newer worktree.
void _validateArtifact(String content) {
  const artifactPath = _artifactPath;
  // Stub rejection: real typegen output contains the Database type and at
  // least one table definition. A placeholder/stub file must fail the gate.
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
}

/// Resolves the complete CI range, fetching history for shallow checkouts.
String _ciBase() {
  // The existing workflow deliberately uses fetch-depth: 2. A multi-commit
  // push needs older history; never silently narrow the gate to HEAD^.
  if (_git(['rev-parse', '--is-shallow-repository']).trim() == 'true') {
    _git(['fetch', '--no-tags', '--unshallow', 'origin']);
  }
  final env = Platform.environment;
  final baseRef = env['GITHUB_BASE_REF'];
  if (baseRef != null && baseRef.isNotEmpty) {
    _git(['check-ref-format', 'refs/heads/$baseRef']);
    _git([
      'fetch',
      '--no-tags',
      'origin',
      'refs/heads/$baseRef:refs/remotes/origin/$baseRef',
    ]);
    final resolved = _git([
      'rev-parse',
      '--verify',
      'refs/remotes/origin/$baseRef^{commit}',
    ]).trim();
    return _git(['merge-base', resolved, 'HEAD']).trim();
  }
  if (env['GITHUB_EVENT_NAME'] == 'push') {
    final eventPath = env['GITHUB_EVENT_PATH'];
    if (eventPath == null || eventPath.isEmpty) {
      throw StateError('Missing push event payload');
    }
    final event =
        jsonDecode(File(eventPath).readAsStringSync()) as Map<String, dynamic>;
    final before = event['before'];
    final after = event['after'];
    final sha = RegExp(r'^[0-9a-f]{40}$');
    if (before is! String ||
        after is! String ||
        !sha.hasMatch(before) ||
        !sha.hasMatch(after) ||
        after != _git(['rev-parse', 'HEAD']).trim()) {
      throw StateError(
        'Invalid push range: require valid before and after matching HEAD',
      );
    }
    // GitHub uses a zero before-id when publishing a new branch. Validate the
    // complete initial snapshot rather than rejecting every first branch push.
    if (before == '0' * 40) return _git(['mktree']).trim();
    return _git(['rev-parse', '--verify', '$before^{commit}']).trim();
  }
  return _git(['rev-parse', '--verify', 'HEAD^']).trim();
}

/// Splits Git's machine-readable output without trimming literal paths.
Set<String> _paths(String output) =>
    output.split('\x00').where((p) => p.isNotEmpty).toSet();

/// Requires either changed artifact bytes or a receipt for the entire batch.
void _checkBatch(Set<String> paths, String base, String? snapshot) {
  final migrations = paths
      .where((p) => p.startsWith('supabase/migrations/'))
      .toSet();
  // Snapshot validity is independent of whether SQL changed. A valid working
  // copy cannot conceal a staged deletion or stub in an artifact-only commit.
  for (final path in migrations) {
    _safePath(path);
  }
  final before = _blob(_artifactPath, base);
  final after = _blob(_artifactPath, snapshot);
  if (after == null) {
    throw StateError('Missing contract artifact in checked snapshot');
  }
  _validateArtifact(
    snapshot == null
        ? File(_artifactPath).readAsStringSync()
        : _git(['cat-file', 'blob', after]),
  );
  if (migrations.isEmpty || before != after) return;
  _verifyReceipt(migrations, base, snapshot);
}

/// Runs Git without a shell; every unexpected nonzero exit closes the gate.
String _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    throw StateError(
      'git ${args.first} failed (${result.exitCode}): ${result.stderr}',
    );
  }
  return result.stdout as String;
}

/// Permits only literal repository-relative paths, never traversal or options.
void _safePath(String path) {
  if (!RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(path) ||
      path.startsWith('/') ||
      path
          .split('/')
          .any(
            (part) =>
                part.isEmpty ||
                part == '.' ||
                part == '..' ||
                part.startsWith('-'),
          )) {
    throw FormatException('Unsafe contract path: $path');
  }
}

/// Reads an exact Git blob ID (no EOL/filter normalization) from one snapshot.
/// A null snapshot means worktree; an empty snapshot means staged index.
String? _blob(String path, String? snapshot) {
  _safePath(path);
  if (snapshot == null) {
    final parts = path.split('/');
    for (var i = 1; i <= parts.length; i++) {
      final type = FileSystemEntity.typeSync(
        parts.take(i).join('/'),
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) return null;
      if (type !=
          (i == parts.length
              ? FileSystemEntityType.file
              : FileSystemEntityType.directory)) {
        throw StateError('Contract path is not a regular file: $path');
      }
    }
    return _git(['hash-object', '--no-filters', '--', path]).trim();
  }
  final listing = snapshot.isEmpty
      ? _git(['ls-files', '--stage', '-z', '--', path])
      : _git(['ls-tree', '-z', snapshot, '--', path]);
  if (listing.isEmpty) return null;
  final records = listing
      .split('\x00')
      .where((line) => line.isNotEmpty)
      .toList();
  if (records.length != 1) throw StateError('Unmerged contract path: $path');
  final fields = records.single.split('\t');
  final meta = fields.first.split(' ');
  if (fields.length != 2 ||
      fields[1] != path ||
      !['100644', '100755'].contains(meta[0]) ||
      (snapshot.isEmpty && meta[2] != '0')) {
    throw StateError('Contract path is not a regular blob: $path');
  }
  return snapshot.isEmpty ? meta[1] : meta[2];
}

/// Requires an explicit, reviewed attestation bound to the entire exact batch.
/// This is review evidence, not a SQL parser or proof of remote deployment.
void _verifyReceipt(Set<String> migrations, String base, String? snapshot) {
  if (_git(['rev-parse', '--show-object-format']).trim() != 'sha1') {
    throw StateError('Receipt version 1 requires git-blob-sha1');
  }
  if (_blob(_receiptPath, snapshot) == null) {
    throw StateError(
      'Migrations changed without updated types or a reviewed receipt ($_receiptPath)',
    );
  }
  final raw = snapshot == null
      ? File(_receiptPath).readAsStringSync()
      : _git(['show', '$snapshot:$_receiptPath']);
  final receipt = jsonDecode(raw) as Map<String, dynamic>;
  final before = _blob(_artifactPath, base);
  final after = _blob(_artifactPath, snapshot);
  if (receipt['version'] != 1 ||
      receipt['hashAlgorithm'] != 'git-blob-sha1' ||
      receipt['artifact'] != _artifactPath ||
      receipt['noTypeShapeChange'] != true ||
      before == null ||
      before != after ||
      receipt['beforeArtifact'] != before ||
      receipt['afterArtifact'] != after) {
    throw StateError('Receipt artifact binding is stale or invalid');
  }
  final regeneration = receipt['regeneration'] as Map<String, dynamic>;
  final review = receipt['review'] as Map<String, dynamic>;
  if (regeneration['command'] !=
          'supabase gen types --lang typescript --linked' ||
      [
        'toolVersion',
        'source',
        'evidence',
      ].any((key) => !_nonempty(regeneration[key])) ||
      [
        'reviewer',
        'reviewedAt',
        'rationale',
      ].any((key) => !_nonempty(review[key])) ||
      DateTime.tryParse(review['reviewedAt'] as String) == null) {
    throw StateError(
      'Receipt requires explicit regeneration and review provenance',
    );
  }
  final entries = receipt['migrations'] as List<dynamic>;
  final seen = <String>{};
  for (final entry in entries) {
    final path = entry['path'] as String;
    _safePath(path);
    if (!migrations.contains(path) ||
        !seen.add(path) ||
        entry['before'] != _blob(path, base) ||
        entry['after'] == null ||
        entry['after'] != _blob(path, snapshot)) {
      throw StateError('Receipt migration binding is stale or invalid: $path');
    }
  }
  if (seen.length != migrations.length) {
    throw StateError('Receipt must cover the exact migration batch');
  }
  print(
    '[OK] Verified no-type-shape-change receipt for ${seen.length} migration(s).',
  );
}

/// Rejects missing, non-string and blank attestation fields.
bool _nonempty(Object? value) => value is String && value.trim().isNotEmpty;
