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
    print('[WARNING] Bootstrap Action Required: The generated types file ($generatedFilePath) does not exist.');
    print('This is expected until a non-production Supabase project is provisioned (e.g. STEP-42).');
    print('Bypassing contract staleness check.');
    exit(0);
  }

  // Detect uncommitted/staged changes first (for local)
  final statusResult = Process.runSync('git', ['status', '--porcelain']);
  final statusOutput = statusResult.stdout.toString();
  
  bool migUncommitted = false;
  bool typeUncommitted = false;
  
  for (var line in statusOutput.split('\n')) {
    if (line.length > 3) {
      final path = line.substring(3).replaceAll('\\', '/');
      if (path.startsWith(migrationsDirPath)) migUncommitted = true;
      if (path.startsWith(generatedFilePath)) typeUncommitted = true;
    }
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
