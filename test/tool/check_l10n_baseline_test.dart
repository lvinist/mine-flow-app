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

  // STEP-48.29 (audit G-3): the line-by-line scan was blind to multi-line
  // Text( literals — 21 of 33 non-exempt files carried 36 of them. These
  // tests pin the multi-line-aware detection contract.
  group('findHardcodedTextViolations', () {
    test('catches a multi-line Text( with single-quoted literal', () {
      const code = '''
Text(
  'Pilih Jenis Laporan',
)
''';
      final violations = findHardcodedTextViolations(code);
      expect(violations, hasLength(1));
      expect(violations.single.snippet, contains("'Pilih Jenis Laporan'"));
    });

    test('catches a multi-line Text( with double-quoted literal', () {
      const code = '''
Text(
  "Double Quoted Label",
)
''';
      final violations = findHardcodedTextViolations(code);
      expect(violations, hasLength(1));
      expect(violations.single.snippet, contains('"Double Quoted Label"'));
    });

    test('still catches single-line literals (unregressed)', () {
      const code = "return Text('Single Line');\n";
      final violations = findHardcodedTextViolations(code);
      expect(violations, hasLength(1));
    });

    test(
      'still catches double-quoted single-line literals (STEP-41.5 ISSUE-4)',
      () {
        const code = 'return Text("Double Single Line");\n';
        final violations = findHardcodedTextViolations(code);
        expect(violations, hasLength(1));
      },
    );

    test('ignores a Text( inside a comment', () {
      const code = '''
// Text(
//   'Commented Out Label',
// )
''';
      expect(findHardcodedTextViolations(code), isEmpty);
    });

    test('ignores empty and 1-char literals', () {
      const code = '''
Text(
  '',
)
Text('x')
''';
      expect(findHardcodedTextViolations(code), isEmpty);
    });

    test('ignores pure-interpolation literals (documented rule)', () {
      const code = '''
Text(
  '\$x',
)
Text(
  '\${model.value}',
)
''';
      expect(findHardcodedTextViolations(code), isEmpty);
    });

    test("flags '\$percent%' — the % is plain text, so it is mixed copy", () {
      const code = '''
Text(
  '\$percent%',
)
''';
      final violations = findHardcodedTextViolations(code);
      expect(
        violations,
        hasLength(1),
        reason:
            'a unit suffix is translatable copy; the ARB key should '
            'carry a {percent} placeholder',
      );
    });

    test('flags mixed text+interpolation literals', () {
      const code = '''
Text(
  'Hello \$name',
)
''';
      final violations = findHardcodedTextViolations(code);
      expect(violations, hasLength(1));
    });

    test('does not flag AppLocalizations getters', () {
      const code = '''
Text(
  AppLocalizations.of(context).reportTypePickerTitle,
)
''';
      expect(findHardcodedTextViolations(code), isEmpty);
    });
  });
}
