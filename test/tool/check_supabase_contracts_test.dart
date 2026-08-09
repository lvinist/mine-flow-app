// Tests the Supabase contract staleness guard.
//
// This test runs the `check_supabase_contracts.dart` script as a subprocess
// to verify its behavior under different conditions. It requires a clean git
// worktree to run correctly and cleans up any temporary files it creates.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scriptPath = 'tool/check_supabase_contracts.dart';
  const generatedFilePath = 'lib/core/data/models/generated/database.dart';
  const tempMigrationPath = 'supabase/migrations/99999999_temp.sql';

  group('check_supabase_contracts guard', () {
    test('fails when generated file does not exist', () {
      final generatedFile = File(generatedFilePath);
      final backup = File('$generatedFilePath.bak');
      if (generatedFile.existsSync()) {
        generatedFile.copySync(backup.path);
        generatedFile.deleteSync();
      }

      try {
        final result = Process.runSync('dart', ['run', scriptPath], runInShell: true);
        expect(result.exitCode, 1);
        expect(result.stdout.toString(), contains('[ERROR]'));
      } finally {
        if (backup.existsSync()) {
          backup.copySync(generatedFilePath);
          backup.deleteSync();
        }
      }
    });

    test('fails when generated file exists but uncommitted migration is staged', () {
      final generatedFile = File(generatedFilePath);
      final tempMigration = File(tempMigrationPath);

      try {
        // Setup: ensure generated file exists and is not modified in git status
        if (!generatedFile.existsSync()) {
            generatedFile.createSync(recursive: true);
            generatedFile.writeAsStringSync('// dummy generated types\n');
        } else {
            Process.runSync('git', ['restore', generatedFilePath], runInShell: true);
        }

        tempMigration.createSync(recursive: true);
        tempMigration.writeAsStringSync('-- temp migration\n');
        
        Process.runSync('git', ['add', tempMigrationPath], runInShell: true);

        // Execute guard
        final result = Process.runSync('dart', ['run', scriptPath], runInShell: true);
        
        // Assert
        expect(result.exitCode, 1);
        expect(result.stdout.toString(), contains('[ERROR]'));
      } finally {
        // Cleanup
        Process.runSync('git', ['restore', '--staged', tempMigrationPath], runInShell: true);
        if (tempMigration.existsSync()) {
          tempMigration.deleteSync();
        }
        Process.runSync('git', ['restore', generatedFilePath], runInShell: true);
      }
    });

    test('passes when generated file exists and no migration change is made', () {
      final generatedFile = File(generatedFilePath);

      try {
        // Setup: ensure generated file exists
        if (!generatedFile.existsSync()) {
            generatedFile.createSync(recursive: true);
            generatedFile.writeAsStringSync('// dummy generated types\n');
        } else {
            Process.runSync('git', ['restore', generatedFilePath], runInShell: true);
        }

        // Execute guard
        final result = Process.runSync('dart', ['run', scriptPath], runInShell: true);
        
        // Assert
        expect(result.exitCode, 0);
        expect(result.stdout.toString(), contains('[OK] Contract verification passed.'));
      } finally {
        // Cleanup
        Process.runSync('git', ['restore', generatedFilePath], runInShell: true);
      }
    });
  });
}
