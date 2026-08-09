// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  const generatedFilePath = 'lib/core/data/models/generated/database.dart';
  final generatedFile = File(generatedFilePath);
  const migrationsDirPath = 'supabase/migrations';

  print('Supabase Contract Check');
  print('-----------------------');
  print('Regeneration Command:');
  print('  supabase gen types dart --project-id \$SUPABASE_PROJECT_ID > $generatedFilePath\n');

  if (!generatedFile.existsSync()) {
    print('[ERROR] The generated types file ($generatedFilePath) does not exist.');
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
    if (path.startsWith(generatedFilePath)) typeUncommitted = true;
  }
  
  if (migUncommitted && !typeUncommitted) {
    print('[ERROR] Uncommitted database migrations found, but $generatedFilePath is not updated.');
    print('Please regenerate the types before committing.');
    exit(1);
  }

  // In CI, checking diff against BASE_REF
  final isCi = Platform.environment['CI'] == 'true';
  if (isCi) {
    final baseRef = Platform.environment['GITHUB_BASE_REF'];
    final base = (baseRef != null && baseRef.isNotEmpty) ? 'origin/$baseRef' : 'HEAD^';
    
    if (baseRef != null && baseRef.isNotEmpty) {
      Process.runSync('git', ['fetch', 'origin', baseRef, '--depth=1']);
    } else {
      Process.runSync('git', ['fetch', '--depth=2']); // Ensure HEAD^ exists
    }

    final diffResult = Process.runSync('git', ['diff', '--name-only', base, 'HEAD']);
    final diffOutput = diffResult.stdout.toString();
    
    bool migChanged = false;
    bool typeChanged = false;
    for (var line in diffOutput.split('\n')) {
      final path = line.replaceAll('\\', '/');
      if (path.startsWith(migrationsDirPath)) migChanged = true;
      if (path.startsWith(generatedFilePath)) typeChanged = true;
    }
    
    if (migChanged && !typeChanged) {
      print('[ERROR] Migrations modified in this PR/push, but $generatedFilePath was not updated.');
      print('You must regenerate the types when modifying the schema.');
      exit(1);
    }
  }

  print('[OK] Contract verification passed.');
}
