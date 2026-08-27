/// Tests for the l10n baseline guard (tool/check_l10n_baseline.dart).
///
/// Runs the guard as a subprocess to verify its pass and fail behavior.
/// Requires a clean git worktree in Code/mine-flow-app.
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_l10n_baseline.dart';

void main() {
  group('check_l10n_baseline guard', () {
    test(
      'passes with the current codebase (all new violations exempt)',
      () async {
        final result = await Process.run(
          'dart',
          ['run', 'tool/check_l10n_baseline.dart'],
          workingDirectory: Directory.current.path,
          runInShell: true,
        );
        expect(
          result.exitCode,
          0,
          reason:
              'Guard should pass when no non-exempt violations exist.\n'
              'stdout: ${result.stdout}\nstderr: ${result.stderr}',
        );
        expect(result.stdout.toString(), contains('[OK]'));
      },
    );

    test(
      'fails when a non-exempt presentation file has a hardcoded string',
      () async {
        // Create a temporary non-exempt presentation file with a hardcoded string.
        final tempDir = Directory(
          'lib/features/_test_l10n_guard_temp_/presentation/pages',
        );
        final tempFile = File('${tempDir.path}/temp_screen.dart');
        try {
          tempDir.createSync(recursive: true);
          tempFile.writeAsStringSync('''
import 'package:flutter/material.dart';

class TempScreen extends StatelessWidget {
  const TempScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Text('Hardcoded String That Should Fail');
  }
}
''');

          final result = await Process.run(
            'dart',
            ['run', 'tool/check_l10n_baseline.dart'],
            workingDirectory: Directory.current.path,
            runInShell: true,
          );
          expect(
            result.exitCode,
            1,
            reason:
                'Guard should fail when a non-exempt file has hardcoded strings.\n'
                'stdout: ${result.stdout}',
          );
          expect(result.stdout.toString(), contains('[ERROR]'));
          expect(result.stdout.toString(), contains('temp_screen.dart'));
        } finally {
          // Always clean up, even if assertion fails.
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        }
      },
    );

    test(
      'fails when a non-exempt file has a double-quoted hardcoded string',
      () async {
        final tempDir = Directory(
          'lib/features/_test_l10n_guard_temp_dq_/presentation/pages',
        );
        final tempFile = File('${tempDir.path}/temp_dq_screen.dart');
        try {
          tempDir.createSync(recursive: true);
          tempFile.writeAsStringSync('''
import 'package:flutter/material.dart';

class TempDqScreen extends StatelessWidget {
  const TempDqScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Text("Double Quoted Hardcoded String");
  }
}
''');
          final result = await Process.run(
            'dart',
            ['run', 'tool/check_l10n_baseline.dart'],
            workingDirectory: Directory.current.path,
            runInShell: true,
          );
          expect(
            result.exitCode,
            1,
            reason:
                'Guard should fail for double-quoted hardcoded strings.\n'
                'stdout: ${result.stdout}',
          );
          expect(result.stdout.toString(), contains('[ERROR]'));
          expect(result.stdout.toString(), contains('temp_dq_screen.dart'));
        } finally {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        }
      },
    );

    // CF-063: router-supplied group-landing labels must be caught.
    test('catches a router-supplied label not in the allowlist', () {
      const synthetic = """
        const GroupLandingPage(
          title: 'Something New',
          subtitle: 'Peralatan',
        );
      """;
      final violations = findRouterLabelViolations(synthetic);
      expect(violations, contains('Something New'));
      expect(violations, isNot(contains('Peralatan')));
    });

    test('allows the current router.dart (labels in the legacy allowlist)', () {
      final content = File('lib/app/router.dart').readAsStringSync();
      expect(findRouterLabelViolations(content), isEmpty);
    });
  });
}
