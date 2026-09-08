/// Tests for the E2E executed guard (tool/ci/check_e2e_executed.dart).
///
/// STEP-48.29 (audit G-2): verifies the guard rejects all-skipped runs on both
/// platforms and accepts runs with real execution evidence, using synthetic
/// fixtures shaped like the captured real logs at the workspace root.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../tool/ci/check_e2e_executed.dart';

void main() {
  group('parseAndroidLog', () {
    test('REJECTS the all-skipped line (+0 ~17: All tests passed!)', () {
      const log = '00:05 +0 ~17: All tests passed!\n';
      final summary = parseAndroidLog(log);
      expect(summary.executed, 0, reason: 'the hole this guard exists to plug');
      expect(summary.passed, 0);
      expect(summary.skipped, 17);
    });

    test('accepts the captured real Android summary (+23 ~3)', () {
      const log = '21:26 +23 ~3: All tests passed!\n';
      final summary = parseAndroidLog(log);
      expect(summary.executed, 23);
      expect(summary.skipped, 3);
    });

    test('accepts a failed run — failed tests still executed (+14 -10 ~2)', () {
      const log = '15:30 +14 -10 ~2: Some tests failed.\n';
      final summary = parseAndroidLog(log);
      expect(summary.executed, 24); // 14 passed + 10 failed
      expect(summary.failed, 10);
      expect(summary.skipped, 2);
    });

    test('accepts the ~skipped-before-failed token order (+7 ~1 -1)', () {
      const log = '09:15 +7 ~1 -1: some journey (tearDownAll)\n';
      final summary = parseAndroidLog(log);
      expect(summary.executed, 8); // 7 passed + 1 failed
      expect(summary.skipped, 1);
    });

    test('uses the LAST progress line in a long log', () {
      const log = '''
Resolving dependencies...
00:01 +0 ~0: loading test suite
00:03 +1: auth journey test passed
10:20 +7 ~1 -1: deep_link_journey_test.dart: (tearDownAll)
21:26 +23 ~3: All tests passed!
''';
      final summary = parseAndroidLog(log);
      expect(summary.executed, 23);
      expect(summary.skipped, 3);
    });

    test('REJECTS a log with no progress line (hung/cancelled run)', () {
      const log = 'Some random output\nNo progress here\n';
      final summary = parseAndroidLog(log);
      expect(summary.finalLine, isNull);
      expect(summary.executed, 0);
    });

    test('parses the captured real Android log from the workspace root', () {
      final logFile = File('../../step4824_r4_android_full.log');
      if (!logFile.existsSync()) {
        markTestSkipped('Captured Android log not available');
        return;
      }
      final summary = parseAndroidLog(logFile.readAsStringSync());
      expect(summary.finalLine, contains('+23 ~3'));
      expect(summary.executed, 23);
      expect(summary.skipped, 3);
    });
  });

  group('parseWebLog (marker era)', () {
    test('REJECTS a 16-file all-skipped aggregate (no markers anywhere)', () {
      final buf = StringBuffer();
      for (var i = 0; i < 16; i++) {
        buf.writeln('MINE_FLOW_E2E_FILE integration_test/journeys/j$i.dart');
        buf.writeln('result {"result":"true","failureDetails":[]}');
        buf.writeln('All tests passed.');
      }
      final summary = parseWebLog(buf.toString());
      expect(
        summary.executed,
        0,
        reason: 'driver completion is not execution evidence',
      );
      expect(summary.files, hasLength(16));
    });

    test('accepts a mixed aggregate: executed + honest named skip', () {
      final buf = StringBuffer();
      buf.writeln('MINE_FLOW_E2E_FILE integration_test/app_boots_test.dart');
      buf.writeln(
        'result {"result":"true","failureDetails":[],"data":{"e2e_executed":["app_boots"],"e2e_skipped":[]}}',
      );
      buf.writeln('All tests passed.');
      buf.writeln(
        'MINE_FLOW_E2E_FILE integration_test/journeys/data_bucket_journey_test.dart',
      );
      buf.writeln(
        'result {"result":"true","failureDetails":[],"data":{"e2e_executed":[],"e2e_skipped":["data_bucket: Drive credentials absent (RISK-0017/0018)"]}}',
      );
      buf.writeln('All tests passed.');
      final summary = parseWebLog(buf.toString());
      expect(summary.executed, 1);
      expect(summary.files, hasLength(2));
      expect(summary.files[0].status, contains('EXECUTED'));
      expect(summary.files[1].status, contains('SKIPPED'));
      expect(summary.noEvidenceFiles, isEmpty);
    });

    test('counts a driver failure as execution (the failing body ran)', () {
      final buf = StringBuffer();
      buf.writeln('MINE_FLOW_E2E_FILE integration_test/journeys/broken.dart');
      buf.writeln(
        'result {"result":"false","failureDetails":[{"error":"boom"}]}',
      );
      final summary = parseWebLog(buf.toString());
      expect(summary.executed, 1);
      expect(summary.files[0].status, 'FAILED (driver)');
    });

    test('REJECTS a marker-era file with result:true and NO markers', () {
      final buf = StringBuffer();
      buf.writeln(
        'MINE_FLOW_E2E_FILE integration_test/journeys/new_journey.dart',
      );
      buf.writeln('result {"result":"true","failureDetails":[]}');
      buf.writeln('All tests passed.');
      buf.writeln(
        'MINE_FLOW_E2E_FILE integration_test/journeys/auth_journey_test.dart',
      );
      buf.writeln(
        'result {"result":"true","failureDetails":[],"data":{"e2e_executed":["auth"]}}',
      );
      final summary = parseWebLog(buf.toString());
      expect(summary.executed, 1); // aggregate rule satisfied
      expect(
        summary.noEvidenceFiles,
        hasLength(1),
        reason:
            'a file with no marker, no skip, no failure is a guard '
            'failure in the marker era',
      );
      expect(summary.noEvidenceFiles.single.file, contains('new_journey'));
    });
  });

  group('parseWebLog (legacy logs, pre-marker)', () {
    test('legacy all-skipped aggregate with no markers is REJECTED', () {
      final buf = StringBuffer();
      for (var i = 0; i < 16; i++) {
        buf.writeln('Resolving dependencies...');
        buf.writeln('result {"result":"true","failureDetails":[]}');
        buf.writeln('All tests passed.');
        buf.writeln('Application finished.');
      }
      final summary = parseWebLog(buf.toString());
      expect(summary.files, hasLength(16));
      expect(summary.executed, 0);
      expect(summary.markerEra, isFalse);
    });

    test('parses the captured real web aggregate from the workspace root', () {
      final logFile = File('../../step4824_e2e_web_all.log');
      if (!logFile.existsSync()) {
        markTestSkipped('Captured web log not available');
        return;
      }
      final summary = parseWebLog(logFile.readAsStringSync());
      // Captured 2026-09-05: 16 file blocks, all result:true, no markers —
      // an all-skip-shaped log that the OLD grep guard accepted. The new
      // guard must classify it as zero-execution evidence.
      expect(summary.files, hasLength(16));
      expect(summary.executed, 0);
      expect(summary.markerEra, isFalse);
    });
  });

  group('CLI exit codes (real subprocess)', () {
    late Directory tmp;
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('e2e_guard_');
    });
    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    Future<ProcessResult> runGuard(String logContent, String platform) {
      final log = File('${tmp.path}/log.txt');
      log.writeAsStringSync(logContent);
      return Process.run(
        'dart',
        [
          'run',
          'tool/ci/check_e2e_executed.dart',
          '--platform=$platform',
          '--log=${log.path}',
        ],
        workingDirectory: Directory.current.path,
        runInShell: true,
      );
    }

    test('CLI FAILS (exit 1) on the all-skipped Android line', () async {
      final result = await runGuard(
        '00:05 +0 ~17: All tests passed!\n',
        'android',
      );
      expect(
        result.exitCode,
        1,
        reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
      );
      expect(result.stdout.toString(), contains('[ERROR]'));
      expect(result.stdout.toString(), contains('Zero tests executed'));
    });

    test('CLI PASSES (exit 0) on the captured real Android log tail', () async {
      final realLog = File('../../step4824_r4_android_full.log');
      if (!realLog.existsSync()) {
        markTestSkipped('Captured Android log not available');
        return;
      }
      // Tail: the last 40 lines contain the final progress line.
      final lines = realLog.readAsLinesSync();
      final tail = lines.sublist(lines.length - 40).join('\n');
      final result = await runGuard(tail, 'android');
      expect(
        result.exitCode,
        0,
        reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
      );
      expect(result.stdout.toString(), contains('[OK]'));
    });

    test(
      'CLI FAILS (exit 1) on a synthetic all-skipped web aggregate',
      () async {
        final buf = StringBuffer();
        for (var i = 0; i < 16; i++) {
          buf.writeln('MINE_FLOW_E2E_FILE integration_test/journeys/j$i.dart');
          buf.writeln('result {"result":"true","failureDetails":[]}');
          buf.writeln('All tests passed.');
        }
        final result = await runGuard(buf.toString(), 'web');
        expect(
          result.exitCode,
          1,
          reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
        );
        expect(result.stdout.toString(), contains('Zero tests executed'));
      },
    );

    test(
      'CLI PASSES (exit 0) on a marker-era web aggregate with execution',
      () async {
        final buf = StringBuffer();
        buf.writeln('MINE_FLOW_E2E_FILE integration_test/app_boots_test.dart');
        buf.writeln(
          'result {"result":"true","failureDetails":[],"data":{"e2e_executed":["app_boots"]}}',
        );
        buf.writeln(
          'MINE_FLOW_E2E_FILE integration_test/journeys/data_bucket_journey_test.dart',
        );
        buf.writeln(
          'result {"result":"true","failureDetails":[],"data":{"e2e_skipped":["data_bucket: Drive absent (RISK-0017/0018)"]}}',
        );
        final result = await runGuard(buf.toString(), 'web');
        expect(
          result.exitCode,
          0,
          reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}',
        );
        expect(result.stdout.toString(), contains('[OK]'));
        expect(result.stdout.toString(), contains('EXECUTED'));
        expect(result.stdout.toString(), contains('SKIPPED'));
      },
    );
  });
}
