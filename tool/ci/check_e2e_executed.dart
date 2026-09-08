// ignore_for_file: avoid_print
/// CI guard: proves an E2E job actually executed at least one test body.
///
/// Usage:
///   dart run tool/ci/check_e2e_executed.dart --platform=android --log=integration_test.log
///   dart run tool/ci/check_e2e_executed.dart --platform=web --log=all_web.log
///
/// **Why this exists (STEP-48.29, audit G-2):** `flutter test` (Android) and
/// `flutter drive` (web) both exit 0 when every test is skipped via
/// `markTestSkipped`. The previous inline grep guard
/// (`grep -qE "\+[1-9]|\-[1-9]|All tests passed|Some tests failed"`) accepted
/// `00:05 +0 ~17: All tests passed!` (0 executed, 17 skipped) on Android, and
/// on web accepted any aggregate containing the literal `All tests passed.` —
/// which `flutter drive` prints once per file even when every test in that
/// file skipped. Both holes were demonstrated before this rewrite.
///
/// **Android log grammar** (`flutter test integration_test/`):
///   The runner prints progress lines `MM:SS +<passed>[ -<failed>][ ~<skipped>]:`
///   (the `-failed`/`~skipped` tokens appear only when non-zero and their
///   relative order varies). The LAST such line is the suite summary.
///   Rule: fail when `passed + failed == 0` on that final line, and fail when
///   no progress line exists at all (a hung/cancelled run leaves none).
///
/// **Web log grammar** (per-file `flutter drive` loop, appended to one log):
///   The CI loop writes `MINE_FLOW_E2E_FILE <path>` before each file, then the
///   file's `flutter drive` output. The extended driver prints exactly one
///   final line `result {"result":"true|false","failureDetails":[...],"data":{...}}`
///   per file. App-side `print()` output is NOT forwarded to this log on web —
///   the only app-to-driver channel is `reportData`, which the driver
///   serializes into that `data` object. The journey helper
///   `recordE2eExecuted`/`recordE2eSkipped` (integration_test/helpers/
///   staging_config.dart) puts `e2e_executed` / `e2e_skipped` lists there.
///   Rules:
///   - A file "executed" if it emitted ≥1 `e2e_executed` marker, OR its driver
///     result is `false` (a failing test body still ran).
///   - Aggregate rule: at least one file must have executed. Individual honest
///     skips (Drive/D2 → RISK-0017/0018, crew → RISK-0021, credentials absent)
///     are tolerated and shown in the per-file table.
///   - Marker-era logs (any marker present): every file must show SOME signal
///     (executed markers, skip markers, or a driver failure). A file with a
///     `true` result and no markers is a journey whose tests all skipped
///     without calling `recordE2eSkipped`, or a new file that does not follow
///     the convention — both are guard failures.
///   - Legacy logs (no markers anywhere, e.g. captured pre-48.29 logs): only
///     the aggregate rule applies; driver failures count as execution because
///     a `false` result cannot be produced by a skipped suite.
library;

import 'dart:convert';
import 'dart:io';

/// Parsed executed-test counts from Flutter's final Android progress line.
class AndroidExecutionSummary {
  const AndroidExecutionSummary({
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.finalLine,
  });

  final int passed;
  final int failed;
  final int skipped;

  /// The last progress line seen (the suite summary), if any.
  final String? finalLine;

  /// Tests whose bodies actually ran. A failed test is still an executed test.
  int get executed => passed + failed;
}

/// One file block from a web `flutter drive` aggregate log.
class WebFileOutcome {
  WebFileOutcome({
    required this.file,
    required this.driverPassed,
    required List<String> executed,
    required List<String> skipped,
  }) : executed = List.unmodifiable(executed),
       skipped = List.unmodifiable(skipped);

  /// File path from the `MINE_FLOW_E2E_FILE` marker, or `(file N)` for
  /// legacy logs without markers.
  final String file;

  /// The driver's `result` verdict; `null` = no result line in this block
  /// (the `flutter drive` invocation crashed or was cancelled).
  final bool? driverPassed;

  /// `e2e_executed` reportData markers — test bodies that ran.
  final List<String> executed;

  /// `e2e_skipped` reportData markers — named, expected skips.
  final List<String> skipped;

  /// Whether this file proves at least one test body ran.
  bool get ran => executed.isNotEmpty || driverPassed == false;

  String get status {
    if (driverPassed == null) return 'NO RESULT LINE';
    if (driverPassed == false) return 'FAILED (driver)';
    if (executed.isNotEmpty) return 'EXECUTED (${executed.length})';
    if (skipped.isNotEmpty) return 'SKIPPED (${skipped.length})';
    return 'NO EVIDENCE';
  }
}

/// Parsed composition of a web `flutter drive` aggregate log.
class WebExecutionSummary {
  const WebExecutionSummary(this.files);

  final List<WebFileOutcome> files;

  /// Total `e2e_executed` markers across all files.
  int get executedMarkers => files.fold(0, (sum, f) => sum + f.executed.length);

  /// Files whose driver result was `false` but emitted no executed markers
  /// still prove one test body ran (the failing one).
  int get executed =>
      executedMarkers +
      files.where((f) => f.driverPassed == false && f.executed.isEmpty).length;

  /// Whether any reportData marker appears anywhere (post-48.29 journeys).
  bool get markerEra =>
      files.any((f) => f.executed.isNotEmpty || f.skipped.isNotEmpty);

  /// Files that produced neither execution evidence, nor a named skip, nor a
  /// driver failure. Empty in a healthy marker-era log.
  List<WebFileOutcome> get noEvidenceFiles => files
      .where((f) => !f.ran && f.skipped.isEmpty && f.driverPassed != false)
      .toList();
}

/// Matches an Android progress line:
/// `MM:SS +<passed>[ -<failed>][ ~<skipped>]:` — token order of `-`/`~`
/// varies, so the counts are captured as a group and re-parsed.
final _androidProgressLine = RegExp(
  r'^\s*\d+:\d{2}\s+\+(\d+)((?:\s+[~-]\d+)*)\s*:',
);

/// The CI loop's per-file boundary marker in the web aggregate log.
final _webFileMarker = RegExp(r'^MINE_FLOW_E2E_FILE\s+(.+)$');

/// The extended driver's final per-file verdict line.
final _webResultLine = RegExp(r'^result\s+(\{.*\})\s*$');

/// Parses the final Flutter progress line and returns aggregate counts.
///
/// Takes the LAST progress line in [content] (the suite summary). Returns
/// zero counts when no progress line exists — a hung or cancelled run leaves
/// none, and that must fail the guard, not pass it vacuously.
AndroidExecutionSummary parseAndroidLog(String content) {
  String? finalLine;
  var passed = 0;
  var failed = 0;
  var skipped = 0;
  for (final raw in content.split('\n')) {
    final line = raw.trimRight();
    final match = _androidProgressLine.firstMatch(line);
    if (match == null) continue;
    finalLine = line.trim();
    passed = int.parse(match.group(1)!);
    final counts = match.group(2) ?? '';
    final failedMatches = RegExp(r'-(\d+)').allMatches(counts).toList();
    final skippedMatches = RegExp(r'~(\d+)').allMatches(counts).toList();
    failed = failedMatches.isEmpty
        ? 0
        : int.parse(failedMatches.last.group(1)!);
    skipped = skippedMatches.isEmpty
        ? 0
        : int.parse(skippedMatches.last.group(1)!);
  }
  return AndroidExecutionSummary(
    passed: passed,
    failed: failed,
    skipped: skipped,
    finalLine: finalLine,
  );
}

/// Parses a web aggregate log into per-file outcomes.
///
/// Blocks are delimited by `MINE_FLOW_E2E_FILE <path>` lines (written by the
/// CI loop). When no such markers exist (legacy captured logs), each `result`
/// line is treated as its own anonymous file block.
WebExecutionSummary parseWebLog(String content) {
  final lines = content.split('\n');
  final hasFileMarkers = lines.any(
    (l) => _webFileMarker.hasMatch(l.trimRight()),
  );

  final files = <WebFileOutcome>[];

  String name = hasFileMarkers ? '' : '(file 1)';
  final executed = <String>[];
  final skipped = <String>[];
  Map<String, dynamic>? resultJson;

  void flush() {
    if (name.isEmpty) return; // noise before the first file marker
    bool? driverPassed;
    if (resultJson != null) {
      driverPassed = resultJson['result'] == 'true';
      final data = resultJson['data'];
      if (data is Map) {
        executed.addAll(
          ((data['e2e_executed'] as List?) ?? const []).cast<String>(),
        );
        skipped.addAll(
          ((data['e2e_skipped'] as List?) ?? const []).cast<String>(),
        );
      }
    }
    files.add(
      WebFileOutcome(
        file: name,
        driverPassed: driverPassed,
        executed: executed,
        skipped: skipped,
      ),
    );
  }

  if (hasFileMarkers) {
    for (final raw in lines) {
      final line = raw.trimRight();
      final marker = _webFileMarker.firstMatch(line);
      if (marker != null) {
        flush();
        name = marker.group(1)!.trim();
        executed.clear();
        skipped.clear();
        resultJson = null;
        continue;
      }
      final result = _webResultLine.firstMatch(line);
      if (result != null) {
        resultJson = _tryDecode(result.group(1)!);
      }
    }
    flush();
  } else {
    // Legacy log: one anonymous block per result line.
    var fileNumber = 0;
    for (final raw in lines) {
      final line = raw.trimRight();
      final result = _webResultLine.firstMatch(line);
      if (result == null) continue;
      fileNumber++;
      final json = _tryDecode(result.group(1)!);
      final data = json?['data'];
      final blockExecuted = (data is Map)
          ? ((data['e2e_executed'] as List?) ?? const [])
                .cast<String>()
                .toList()
          : <String>[];
      final blockSkipped = (data is Map)
          ? ((data['e2e_skipped'] as List?) ?? const []).cast<String>().toList()
          : <String>[];
      files.add(
        WebFileOutcome(
          file: '(file $fileNumber)',
          driverPassed: json == null ? null : json['result'] == 'true',
          executed: blockExecuted,
          skipped: blockSkipped,
        ),
      );
    }
  }

  return WebExecutionSummary(files);
}

Map<String, dynamic>? _tryDecode(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return null;
  } on FormatException {
    return null;
  }
}

void _printAndroidSummary(AndroidExecutionSummary summary) {
  print('Android E2E execution summary:');
  print('  Final progress line: ${summary.finalLine ?? '(none)'}');
  print(
    '  Passed: ${summary.passed}, Failed: ${summary.failed}, '
    'Skipped: ${summary.skipped}',
  );
  print('  Executed (passed+failed): ${summary.executed}');
}

void _printWebSummary(WebExecutionSummary summary) {
  print('Web E2E execution summary:');
  print('  Files in aggregate: ${summary.files.length}');
  print('  Executed markers: ${summary.executedMarkers}');
  print('  Per-file composition:');
  for (final f in summary.files) {
    print('    ${f.file}: ${f.status}');
    for (final reason in f.skipped) {
      print('      skip: $reason');
    }
  }
}

void main(List<String> args) {
  String? platform;
  String? logPath;
  for (final arg in args) {
    if (arg.startsWith('--platform=')) {
      platform = arg.substring('--platform='.length);
    } else if (arg.startsWith('--log=')) {
      logPath = arg.substring('--log='.length);
    }
  }
  if (platform == null ||
      logPath == null ||
      (platform != 'android' && platform != 'web')) {
    print(
      'usage: dart run tool/ci/check_e2e_executed.dart '
      '--platform=android|web --log=<path>',
    );
    exit(2);
  }

  final logFile = File(logPath);
  if (!logFile.existsSync()) {
    print('[ERROR] log file not found: $logPath');
    exit(2);
  }
  final content = logFile.readAsStringSync();

  if (platform == 'android') {
    final summary = parseAndroidLog(content);
    _printAndroidSummary(summary);
    if (summary.executed == 0) {
      print(
        '[ERROR] Zero tests executed (passed=${summary.passed}, '
        'failed=${summary.failed}, skipped=${summary.skipped}). '
        'A green e2e-android job requires at least one test to pass or fail.',
      );
      exit(1);
    }
    print('[OK] Android execution proven: ${summary.executed} executed.');
    exit(0);
  }

  final summary = parseWebLog(content);
  _printWebSummary(summary);
  if (summary.files.isEmpty) {
    print(
      '[ERROR] No per-file result lines found in the aggregate. '
      'A hung or crashed loop leaves none — this is not a pass.',
    );
    exit(1);
  }
  if (summary.executed == 0) {
    print(
      '[ERROR] Zero tests executed across ${summary.files.length} files: '
      'no e2e_executed markers and no driver failures. Driver completion '
      '("All tests passed.") is not execution evidence — flutter drive '
      'prints it even when every test skipped.',
    );
    exit(1);
  }
  if (summary.markerEra) {
    final noEvidence = summary.noEvidenceFiles;
    if (noEvidence.isNotEmpty) {
      print(
        '[ERROR] Files with no execution evidence, no named skip, and no '
        'driver failure (every test must call recordE2eExecuted after its '
        'skip gates, or recordE2eSkipped before markTestSkipped):',
      );
      for (final f in noEvidence) {
        print('  ${f.file}');
      }
      exit(1);
    }
  }
  print('[OK] Web execution proven: ${summary.executed} executed.');
  exit(0);
}
