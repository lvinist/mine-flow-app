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
];

/// Pattern that detects hardcoded user-facing string literals in Text() calls.
/// Matches both single-quoted and double-quoted forms:
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
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Skip comment lines
        if (line.trimLeft().startsWith('//')) continue;
        if (_hardcodedTextPattern.hasMatch(line)) {
          violations.add('$path:${i + 1}  ${line.trim()}');
        }
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
      violations.add('lib/app/router.dart  router-supplied label: \'$label\'');
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
