// ignore_for_file: avoid_print
/// Localization regression guard for mine-flow.
///
/// Scans Flutter presentation/app Dart files for hardcoded user-facing
/// string patterns (Text('...') and similar) not found in the ARB catalog.
///
/// Strategy: baseline-manifest model. The known list of files with
/// legacy hardcoded strings is recorded in [_legacyExemptFiles]. New
/// files NOT in this list are scanned. Any [Text('...')] usage in a
/// non-exempt file causes a CI failure.
///
/// MAINTENANCE: When a file is migrated to AppLocalizations, remove it
/// from [_legacyExemptFiles]. When a new presentation file is added,
/// it must use AppLocalizations from day one — it will not be auto-exempt.
///
/// **Detection scope:** Both single-line and multi-line forms are detected:
///   Text('literal')          — single-line
///   Text(                    — multi-line: Text( on one line,
///     'literal',             —   literal on a subsequent line
///   )
///
/// **Interpolation rule:** A string containing ONLY interpolation expressions
/// (`'$x'`, `'${y.z}'`) is NOT user-facing copy and is excluded. A string
/// with mixed content (`'Hello $name'`) IS user-facing and is flagged.
/// Rationale: pure-interpolation strings are computed values, not translatable
/// copy. Mixed strings contain translatable text around the interpolation.
///
/// Run: dart run tool/check_l10n_baseline.dart
library;

import 'dart:io';

/// Files that currently have legacy hardcoded strings and are explicitly
/// exempted from the guard until they are migrated in a future STEP.
///
/// IMPORTANT: This list must be COMPLETE and accurate.
/// To discover which presentation files currently have hardcoded Text() literals, run:
///   dart run tool/check_l10n_baseline.dart
/// and read its [ERROR] output — those files need to be added here (temporarily)
/// or migrated to AppLocalizations.
///
/// When migrating a file to AppLocalizations, remove it from this list.
/// When adding a NEW presentation file, do NOT add it here — use AppLocalizations
/// from day one so it is enforced by this guard immediately.
///
/// TODO: All files in this list need AppLocalizations migration.
/// Remove each file when it is migrated. Tracked in RISK-0004.
const List<String> _legacyExemptFiles = [
  'lib/features/attendance/presentation/pages/attendance_form_page.dart',
  'lib/features/attendance/presentation/pages/attendance_screen.dart',
  'lib/features/attendance/presentation/widgets/crew_roster_item.dart',
  'lib/features/auth/presentation/pages/login_page.dart',
  'lib/features/benchmark/presentation/pages/benchmark_form_screen.dart',
  'lib/features/benchmark/presentation/pages/benchmark_list_screen.dart',
  'lib/features/daily_log/presentation/pages/daily_log_form_screen.dart',
  'lib/features/daily_log/presentation/pages/daily_log_list_screen.dart',
  'lib/features/data_bucket/presentation/pages/data_bucket_list_page.dart',
  'lib/features/data_bucket/presentation/pages/file_detail_page.dart',
  'lib/features/data_bucket/presentation/pages/upload_file_page.dart',
  'lib/features/data_bucket/presentation/widgets/file_card.dart',
  'lib/features/equipment_check/presentation/pages/equipment_check_form_screen.dart',
  'lib/features/equipment_check/presentation/pages/equipment_history_screen.dart',
  'lib/features/equipment_check/presentation/widgets/sop_checklist_item_card.dart',
  'lib/features/notifications/presentation/pages/notification_list_page.dart',
  'lib/features/notifications/presentation/widgets/notification_banner.dart',
  'lib/features/reporting/presentation/pages/report_config_page.dart',
  'lib/features/reporting/presentation/widgets/date_range_selector.dart',
  'lib/features/reporting/presentation/widgets/report_type_card.dart',
  'lib/features/settings/presentation/pages/settings_page.dart',
  'lib/features/timeline/presentation/pages/timeline_page.dart',
  'lib/features/tracking/presentation/pages/cut_fill_form_screen.dart',
  'lib/features/tracking/presentation/pages/cut_fill_list_screen.dart',
  'lib/features/tracking/presentation/pages/inventory_dashboard_screen.dart',
  'lib/features/tracking/presentation/pages/inventory_item_entry_screen.dart',
  'lib/features/tracking/presentation/pages/land_clearing_entry_screen.dart',
  'lib/features/tracking/presentation/pages/land_clearing_list_screen.dart',
  'lib/features/tracking/presentation/pages/stock_adjustment_dialog.dart',
  // ── Q16 exemptions (48.29) ─────────────────────────────────────────────────
  // 19 pre-guard files: created STEP-12 or STEP-31 (2026-07-20 / 2026-07-23),
  // before the STEP-41 guard landed (2026-08-03). They carry legacy multi-line
  // Text() literals the pre-48.29 line-by-line scan could not see. Tracked in
  // RISK-0004 alongside the original 29.
  // TODO: Migrate to AppLocalizations. Remove each file when migrated.
  'lib/app/presentation/pages/app_shell.dart', // STEP-31 (2026-07-23)
  'lib/app/presentation/pages/dashboard_page.dart', // STEP-12 (2026-07-20)
  'lib/app/presentation/widgets/global_app_header.dart', // STEP-31 (2026-07-23)
  'lib/features/attendance/presentation/widgets/attendance_summary_card.dart', // STEP-12
  'lib/features/daily_log/presentation/widgets/weather_selector.dart', // STEP-12
  'lib/features/daily_log/presentation/widgets/zone_picker.dart', // STEP-12
  'lib/features/data_bucket/presentation/widgets/upload_progress_indicator.dart', // STEP-12
  'lib/features/equipment_check/presentation/widgets/equipment_check_card.dart', // STEP-12
  'lib/features/reporting/presentation/widgets/report_summary_card.dart', // STEP-12
  'lib/features/timeline/presentation/widgets/milestone_card.dart', // STEP-12
  'lib/features/timeline/presentation/widgets/timeline_chart.dart', // STEP-12
  'lib/features/tracking/presentation/widgets/clearing_summary_card.dart', // STEP-12
  'lib/features/tracking/presentation/widgets/cut_fill_card.dart', // STEP-12
  'lib/features/tracking/presentation/widgets/inventory_card.dart', // STEP-12
  'lib/features/tracking/presentation/widgets/inventory_summary_card.dart', // STEP-12
  'lib/features/tracking/presentation/widgets/land_clearing_card.dart', // STEP-12
  'lib/features/tracking/presentation/widgets/volume_summary_card.dart', // STEP-12
  // Q16 fixed (NOT exempt): the two post-guard STEP-46.4 files —
  // report_type_picker_page.dart and file_detail_route.dart — were migrated
  // to AppLocalizations in 48.29 (keys reportTypePickerTitle /
  // fileDetailNotFound). They were created AFTER the guard landed and are
  // exactly what the guard exists to catch; exempting them would repeat the
  // offence the guard prevents.
];

/// Pattern that detects hardcoded user-facing string literals in Text() calls.
/// Matches both single-quoted and double-quoted forms ON A SINGLE LINE:
///   Text('some label')  — single-quote form
///   Text("some label")  — double-quote form
///
/// Excluded by design:
/// - Strings shorter than 2 chars — not meaningful copy.
/// - Empty strings: Text('') or Text("") — not user-facing copy.
/// - Variables: Text(someVar) — no surrounding quote characters.
/// - Comment lines (filtered separately before matching).
final _hardcodedTextPattern = RegExp(
  'Text\\s*\\(\\s*\'[^\']{2,}\'|Text\\s*\\(\\s*"[^"]{2,}"',
);

/// Pattern that detects group-landing labels passed to [GroupLandingPage] /
/// [FeatureTileConfig] as constructor args from `router.dart` (e.g.
/// `title: 'Peralatan'`). The presentation scan above only covers pages/
/// widgets, so a screen could otherwise defeat the guard by taking its
/// strings from the router (CF-063).
final _routerLabelPattern = RegExp(
  "(title|subtitle|label|description)\\s*:\\s*'([^']{2,})'",
);

/// Current router-supplied labels (legacy), to be migrated to
/// AppLocalizations in RISK-0004. Any NEW router-supplied label not in this
/// list is a violation.
const _legacyRouterLabels = <String>{
  'Peralatan',
  'Alat dan utilitas tambahan',
  'Data Bucket',
  'Penyimpanan data geospasial',
  'Operasi',
  'Manajemen pelacakan operasi lapangan',
  'Cut / Fill',
  'Volume & material',
  'Land Clearing',
  'Area pembukaan',
  'Benchmark DB',
  'Database benchmark',
  'Tim',
  'Kehadiran kru dan dokumentasi harian',
  'Attendance',
  'Kehadiran kru',
  'Daily Log',
  'Laporan lapangan',
  'Inventory',
  'Stok barang',
  'Equipment Check',
  'Inspeksi alat',
  'Timeline Pekerjaan',
  'Jadwal & progres',
};

/// Returns router-supplied labels in [content] that are not in the legacy
/// allowlist. Exposed for unit testing (see test/tool/check_l10n_baseline_test.dart).
List<String> findRouterLabelViolations(String content) {
  final violations = <String>[];
  for (final match in _routerLabelPattern.allMatches(content)) {
    final literal = match.group(2)!;
    if (!_legacyRouterLabels.contains(literal)) {
      violations.add(literal);
    }
  }
  return violations;
}

/// Returns whether a string literal contains ONLY interpolation (no plain text).
///
/// Examples:
///   '$x'         → true  (pure interpolation)
///   '${y.z}'     → true  (pure interpolation)
///   '$x$y'       → true  (pure interpolation)
///   'Hello $x'   → false (mixed: "Hello " is plain text)
///   'abc'        → false (no interpolation at all)
///   ''           → false (empty)
///
/// A pure-interpolation string is NOT user-facing translatable copy.
bool isPureInterpolation(String literal) {
  if (literal.isEmpty) return false;
  // Remove all interpolation expressions: ${...} and $identifier
  final stripped = literal
      .replaceAll(RegExp(r'\$\{[^}]+\}'), '')
      .replaceAll(RegExp(r'\$[a-zA-Z_][a-zA-Z0-9_]*'), '');
  // If nothing remains (or only whitespace), it's pure interpolation
  return stripped.trim().isEmpty && literal.contains(r'$');
}

/// A single hardcoded-text violation found by [findHardcodedTextViolations].
class TextViolation {
  final int lineNumber; // 1-based
  final String snippet; // the matched code fragment

  TextViolation(this.lineNumber, this.snippet);
}

/// Finds hardcoded Text() literals in [content], including multi-line forms.
///
/// Detects:
///   Text('literal')           — single-line, single-quoted
///   Text("literal")           — single-line, double-quoted
///   Text(                     — multi-line: Text( on one line,
///     'literal',              —   literal on a subsequent line
///   )
///   Text(                     — multi-line, double-quoted
///     "literal",
///   )
///
/// Excluded:
///   - Comment lines (lines starting with //)
///   - Strings shorter than 2 chars
///   - Empty strings
///   - Pure-interpolation strings (see [isPureInterpolation])
///
/// Exposed for unit testing.
List<TextViolation> findHardcodedTextViolations(String content) {
  final violations = <TextViolation>[];
  final lines = content.split('\n');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();

    // Skip comment lines
    if (trimmed.startsWith('//')) continue;

    // Check single-line pattern first (existing behavior)
    if (_hardcodedTextPattern.hasMatch(line)) {
      // Extract the literal to check for pure interpolation
      final singleMatch = RegExp(
        "Text\\s*\\(\\s*'([^']{2,})'|Text\\s*\\(\\s*\"([^\"]{2,})\"",
      ).firstMatch(line);
      if (singleMatch != null) {
        final literal = singleMatch.group(1) ?? singleMatch.group(2)!;
        if (!isPureInterpolation(literal)) {
          violations.add(TextViolation(i + 1, line.trim()));
        }
      }
      continue;
    }

    // Check for multi-line pattern: Text( at end of line (possibly with
    // whitespace or a comment after), then a string literal on a following line.
    // Match: `Text(` possibly followed by whitespace, nothing else meaningful.
    final textOpenMatch = RegExp(r'Text\s*\(\s*$').hasMatch(trimmed);
    if (!textOpenMatch) {
      // Also match: `Text(\n` where Text( is followed by only whitespace
      // but there may be other tokens before Text on the same line
      final partialMatch = RegExp(r'Text\s*\(\s*$').hasMatch(line.trim());
      if (!partialMatch) continue;
    }

    // Look ahead for the string literal on the next non-empty, non-comment line
    for (var j = i + 1; j < lines.length && j <= i + 3; j++) {
      final nextTrimmed = lines[j].trimLeft();
      if (nextTrimmed.isEmpty) continue;
      if (nextTrimmed.startsWith('//')) continue;

      // Check for a string literal: 'xxx' or "xxx"
      final literalMatch = RegExp(
        "^\\s*'([^']{2,})'|^\\s*\"([^\"]{2,})\"",
      ).firstMatch(lines[j]);
      if (literalMatch != null) {
        final literal = literalMatch.group(1) ?? literalMatch.group(2)!;
        if (!isPureInterpolation(literal)) {
          violations.add(
            TextViolation(i + 1, '${lines[i].trim()} ${lines[j].trim()}'),
          );
        }
      }
      break; // only check the first non-empty, non-comment line after Text(
    }
  }

  return violations;
}

void main() {
  print('Localization Baseline Guard');
  print('---------------------------');

  final presentationDirs = ['lib/app/presentation', 'lib/features'];

  final violations = <String>[];
  int filesScanned = 0;
  int filesExempt = 0;

  for (final dirPath in presentationDirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) continue;

      // Only check presentation-layer files (pages + widgets, not blocs)
      final isPresentation =
          path.contains('/presentation/pages/') ||
          path.contains('/presentation/widgets/') ||
          path.contains('/app/presentation/pages/') ||
          path.contains('/app/presentation/widgets/');
      if (!isPresentation) continue;

      // Skip exempt (legacy) files
      final isExempt = _legacyExemptFiles.any(
        (exempt) => path.endsWith(exempt),
      );
      if (isExempt) {
        filesExempt++;
        continue;
      }

      filesScanned++;
      final content = entity.readAsStringSync();

      // Use the new multi-line-aware detection
      final textViolations = findHardcodedTextViolations(content);
      for (final v in textViolations) {
        violations.add('$path:${v.lineNumber}  ${v.snippet}');
      }
    }
  }

  print('Files scanned (non-exempt): $filesScanned');
  print('Files exempt (legacy):      $filesExempt');
  print('');

  // CF-063: scan router.dart for group-landing labels passed as constructor
  // args — the presentation scan above only covers pages/widgets, so a screen
  // could defeat the guard by taking its strings from the router.
  final routerFile = File('lib/app/router.dart');
  if (routerFile.existsSync()) {
    final routerLabels = findRouterLabelViolations(
      routerFile.readAsStringSync(),
    );
    for (final label in routerLabels) {
      violations.add("lib/app/router.dart  router-supplied label: '$label'");
    }
  }

  if (violations.isEmpty) {
    print('[OK] No new hardcoded strings detected in non-exempt files.');
    exit(0);
  }

  print('[ERROR] Hardcoded string literals found in non-exempt files:');
  for (final v in violations) {
    print('  $v');
  }
  print('');
  print(
    "To fix: use AppLocalizations.of(context).yourKey instead of Text('...').",
  );
  print(
    'If this file must remain legacy temporarily, add it to _legacyExemptFiles',
  );
  print(
    'in tool/check_l10n_baseline.dart with a TODO referencing the migration STEP.',
  );
  exit(1);
}
