// Real subprocess tests. All Git writes happen in disposable repositories;
// neither the application checkout nor its index/artifact is ever changed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const artifactPath = 'supabase/types/database.ts';
const receiptPath = 'supabase/types/no_shape_change.json';
const migrationPath = 'supabase/migrations/20261004000001_permissions.sql';
final scriptPath = File('tool/check_supabase_contracts.dart').absolute.path;

/// A deliberately synthetic contract fixture, never a production artifact.
String validArtifact() =>
    'export type Database = {\n'
    '  __InternalSupabase: { PostgrestVersion: "14.15" }\n'
    '  public: { Tables: { inventory_transactions: {\n'
    '    Row: { hazard_state: string; hazard_severity: string;\n'
    '      hazard_notes: string; hazard_action: string }\n'
    '  } } }\n}\n${'// synthetic test padding\n' * 100}';

/// Owns an isolated worktree and an on-disk origin; no network is used.
class Fixture {
  Fixture() {
    final scratch = Platform.environment['TMPDIR'];
    root = (scratch == null ? Directory.systemTemp : Directory(scratch))
        .createTempSync('contract-guard-');
    repo = Directory('${root.path}/repo')..createSync();
    git(['init', '-b', 'main']);
    git(['config', 'user.name', 'Contract fixture']);
    git(['config', 'user.email', 'fixture@example.invalid']);
    git(['config', 'core.autocrlf', 'false']);
    git(['config', 'commit.gpgsign', 'false']);
    write(artifactPath, validArtifact());
    commit();
    base = git(['rev-parse', 'HEAD']).trim();
    final origin = '${root.path}/origin.git';
    git(['clone', '--bare', repo.path, origin]);
    git(['remote', 'add', 'origin', origin]);
    git(['fetch', 'origin']);
  }

  late final Directory root;
  late Directory repo;
  late final String base;

  /// Never lets ambient CI/Git variables redirect a fixture into the real repo.
  Map<String, String> environment([Map<String, String> overrides = const {}]) =>
      {
        for (final entry in Platform.environment.entries)
          if (!entry.key.startsWith('GIT_') &&
              !entry.key.startsWith('GITHUB_') &&
              entry.key != 'CI')
            entry.key: entry.value,
        'CI': 'false',
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_CONFIG_GLOBAL': '${root.path}/no-global-config',
        ...overrides,
      };

  /// Runs real Git, and rejects any fixture setup failure immediately.
  String git(List<String> args) {
    final result = Process.runSync(
      'git',
      args,
      workingDirectory: repo.path,
      environment: environment(),
      includeParentEnvironment: false,
    );
    if (result.exitCode != 0) {
      throw StateError('git $args: ${result.stdout}\n${result.stderr}');
    }
    return result.stdout as String;
  }

  /// Writes only beneath this disposable worktree.
  void write(String path, String content) {
    File('${repo.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  /// Commits only fixture files; never runs Git in the application checkout.
  void commit() {
    git(['add', '--all']);
    git(['commit', '--allow-empty', '-m', 'fixture']);
  }

  /// Records a synthetic reviewed no-shape-change attestation for this fixture.
  Map<String, Object?> receipt() => {
    'version': 1,
    'hashAlgorithm': 'git-blob-sha1',
    'artifact': artifactPath,
    'beforeArtifact': git(['rev-parse', '$base:$artifactPath']).trim(),
    'afterArtifact': git(['hash-object', '--no-filters', artifactPath]).trim(),
    'migrations': [
      {
        'path': migrationPath,
        'before': null,
        'after': git(['hash-object', '--no-filters', migrationPath]).trim(),
      },
    ],
    'noTypeShapeChange': true,
    'regeneration': {
      'command': 'supabase gen types --lang typescript --linked',
      'toolVersion': 'test-fixture',
      'source': 'disposable fixture, not a live database',
      'evidence': 'synthetic fixture output compared byte-for-byte',
    },
    'review': {
      'reviewer': 'test fixture',
      'reviewedAt': '2026-10-06T00:00:00Z',
      'rationale': 'Synthetic fixture models a trigger-only migration.',
    },
  };

  /// Serializes the attestation as ordinary version-controlled JSON.
  void writeReceipt([Map<String, Object?>? value]) =>
      write(receiptPath, jsonEncode(value ?? receipt()));

  /// Executes the actual guard with the fixture as its working directory.
  ProcessResult run([Map<String, String> env = const {}]) => Process.runSync(
    'dart',
    [scriptPath],
    workingDirectory: repo.path,
    environment: environment(env),
    includeParentEnvironment: false,
    runInShell: Platform.isWindows,
  );

  /// Removes only the disposable root.
  void dispose() => root.deleteSync(recursive: true);
}

/// Includes child output in a failed expectation instead of hiding the cause.
void expectExit(ProcessResult result, int code, [String? message]) {
  expect(result.exitCode, code, reason: '${result.stdout}\n${result.stderr}');
  if (message != null) expect(result.stdout, contains(message));
}

void main() {
  late Fixture fixture;
  setUp(() => fixture = Fixture());
  tearDown(() => fixture.dispose());

  test('fails when the artifact is missing', () {
    File('${fixture.repo.path}/$artifactPath').deleteSync();
    expectExit(fixture.run(), 1, '[ERROR]');
  });

  test('rejects a hand-written stub', () {
    fixture.write(artifactPath, '// not typegen\n');
    expectExit(fixture.run(), 1, 'does not look like');
  });

  test('rejects a staged migration without regenerated types', () {
    fixture.write(
      migrationPath,
      'alter table users add column missing text;\n',
    );
    fixture.git(['add', migrationPath]);
    expectExit(fixture.run(), 1, '[ERROR]');
  });

  test('staged stub cannot be hidden by a valid worktree artifact', () {
    fixture.write(
      migrationPath,
      'alter table users add column missing text;\n',
    );
    fixture.write(artifactPath, '// staged stub\n');
    fixture.git(['add', migrationPath, artifactPath]);
    fixture.write(
      artifactPath,
      '${validArtifact()}// regenerated worktree only\n',
    );
    expectExit(fixture.run(), 1, 'does not look like');
  });

  for (final mutation in ['delete', 'stub']) {
    test('artifact-only staged $mutation is validated independently', () {
      if (mutation == 'delete') {
        fixture.git(['rm', artifactPath]);
      } else {
        fixture.write(artifactPath, '// staged stub\n');
        fixture.git(['add', artifactPath]);
      }
      fixture.write(artifactPath, validArtifact());
      expectExit(fixture.run(), 1, '[ERROR]');
    });
  }

  test('accepts a clean contract', () {
    expectExit(fixture.run(), 0, '[OK] Contract verification passed.');
  });

  test('accepts reviewed untracked migrations locally', () {
    fixture.write(migrationPath, '-- synthetic trigger-only migration\n');
    fixture.writeReceipt();
    expectExit(fixture.run(), 0, 'Verified no-type-shape-change');
  });

  test('rejects a staged migration hidden by a worktree deletion', () {
    fixture.write(migrationPath, 'alter table users add column hidden text;\n');
    fixture.git(['add', migrationPath]);
    File('${fixture.repo.path}/$migrationPath').deleteSync();
    expectExit(fixture.run(), 1, '[ERROR]');
  });

  test('CI cannot use an uncommitted receipt to bless HEAD', () {
    fixture.write(migrationPath, '-- synthetic trigger-only migration\n');
    fixture.commit();
    fixture.writeReceipt();
    expectExit(fixture.run({'CI': 'true'}), 1, '[ERROR]');
  });

  test('CI fails closed when its PR base is missing', () {
    fixture.commit();
    expectExit(
      fixture.run({'CI': 'true', 'GITHUB_BASE_REF': 'missing'}),
      1,
      '[ERROR]',
    );
  });

  test('PR compares from merge-base, not the advancing target tip', () {
    fixture.git(['checkout', '-b', 'target']);
    fixture.write(
      migrationPath,
      'alter table users add column target_only text;\n',
    );
    fixture.commit();
    fixture.git(['push', 'origin', 'target']);
    fixture.git(['checkout', 'main']);
    fixture.commit();
    expectExit(fixture.run({'CI': 'true', 'GITHUB_BASE_REF': 'target'}), 0);
  });

  test('push range includes migrations before the last commit', () {
    fixture.write(migrationPath, 'alter table users add column missed text;\n');
    fixture.commit();
    fixture.commit();
    fixture.write(
      'event.json',
      jsonEncode({
        'before': fixture.base,
        'after': fixture.git(['rev-parse', 'HEAD']).trim(),
      }),
    );
    expectExit(
      fixture.run({
        'CI': 'true',
        'GITHUB_EVENT_NAME': 'push',
        'GITHUB_EVENT_PATH': '${fixture.repo.path}/event.json',
      }),
      1,
      '[ERROR]',
    );
  });

  test('shallow CI checkout verifies the complete push range', () {
    fixture.write(migrationPath, '-- synthetic trigger-only migration\n');
    fixture.writeReceipt();
    fixture.commit();
    fixture.commit();
    fixture.commit();
    final head = fixture.git(['rev-parse', 'HEAD']).trim();
    final shallow = Directory('${fixture.root.path}/shallow');
    fixture.git([
      'clone',
      '--no-local',
      '--depth',
      '2',
      fixture.repo.path,
      shallow.path,
    ]);
    fixture.repo = shallow;
    fixture.write(
      'event.json',
      jsonEncode({'before': fixture.base, 'after': head}),
    );
    expectExit(
      fixture.run({
        'CI': 'true',
        'GITHUB_EVENT_NAME': 'push',
        'GITHUB_EVENT_PATH': '${shallow.path}/event.json',
      }),
      0,
      'Verified no-type-shape-change',
    );
  });

  test('shallow PR checkout fetches its target branch', () {
    fixture.git(['checkout', '-b', 'target']);
    fixture.commit();
    fixture.git(['checkout', 'main']);
    fixture.commit();
    final shallow = Directory('${fixture.root.path}/shallow');
    fixture.git([
      'clone',
      '--no-local',
      '--depth',
      '2',
      '--single-branch',
      '--branch',
      'main',
      fixture.repo.path,
      shallow.path,
    ]);
    fixture.repo = shallow;
    expectExit(fixture.run({'CI': 'true', 'GITHUB_BASE_REF': 'target'}), 0);
  });

  test('new branch push validates against an empty tree', () {
    fixture.write(
      'event.json',
      jsonEncode({
        'before': '0' * 40,
        'after': fixture.git(['rev-parse', 'HEAD']).trim(),
      }),
    );
    expectExit(
      fixture.run({
        'CI': 'true',
        'GITHUB_EVENT_NAME': 'push',
        'GITHUB_EVENT_PATH': '${fixture.repo.path}/event.json',
      }),
      0,
    );
  });

  for (final defect in [
    'sql changed',
    'artifact changed',
    'partial batch',
    'duplicate',
    'missing provenance',
    'malformed',
    'unsafe path',
  ]) {
    test('receipt rejects $defect', () {
      fixture.write(migrationPath, '-- synthetic trigger-only migration\n');
      final receipt = fixture.receipt();
      if (defect == 'sql changed') {
        fixture.write(
          migrationPath,
          'alter table users add column unreviewed text;\n',
        );
      }
      if (defect == 'artifact changed') receipt['afterArtifact'] = '0' * 40;
      if (defect == 'partial batch') {
        fixture.write('supabase/migrations/other.sql', '-- unreviewed\n');
      }
      if (defect == 'duplicate') {
        (receipt['migrations'] as List).add(
          (receipt['migrations'] as List).first,
        );
      }
      if (defect == 'missing provenance') receipt['review'] = {};
      if (defect == 'unsafe path') {
        ((receipt['migrations'] as List).first as Map)['path'] =
            '../outside.sql';
      }
      fixture.writeReceipt(receipt);
      if (defect == 'malformed') fixture.write(receiptPath, '{broken');
      expectExit(fixture.run(), 1, '[ERROR]');
    });
  }

  test('shape migration with changed valid artifact passes', () {
    fixture.write(
      migrationPath,
      'alter table users add column present text;\n',
    );
    fixture.write(
      artifactPath,
      '${validArtifact()}// changed generated fixture\n',
    );
    fixture.git(['add', migrationPath, artifactPath]);
    expectExit(fixture.run(), 0);
  });

  test('receipt does not bypass targeted stale-table checks', () {
    fixture.write(
      artifactPath,
      validArtifact().replaceAll('inventory_transactions:', 'wrong_table:'),
    );
    fixture.write(migrationPath, '-- trigger only\n');
    fixture.writeReceipt();
    expectExit(fixture.run(), 1, 'table definition is absent');
  });

  test('accepts a reviewed hash-bound no-shape migration in CI', () {
    fixture.write(migrationPath, '-- synthetic trigger-only migration\n');
    fixture.writeReceipt();
    fixture.commit();
    expectExit(fixture.run({'CI': 'true'}), 0, 'Verified no-type-shape-change');
  });
}
