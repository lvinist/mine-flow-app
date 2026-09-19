import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// PNG specification 8-byte magic signature.
const List<int> _pngMagic = [137, 80, 78, 71, 13, 10, 26, 10];

/// Historical step directories whose committed artifacts must never be clobbered.
const List<String> _protectedHistoricalSteps = [
  'step-0048',
  'step-0045',
  'step-0046',
  'step-0047',
  'step-0050',
  'step-0054',
];

/// Validates that incoming screenshot bytes represent real, non-placeholder PNG image data.
bool _validateScreenshotBytes(String name, List<int> bytes) {
  if (bytes.isEmpty) {
    stderr.writeln('[driver] ERROR: Screenshot "$name" received 0 bytes.');
    return false;
  }

  if (bytes.length < 8) {
    stderr.writeln(
      '[driver] ERROR: Screenshot "$name" length (${bytes.length}) is shorter than PNG header.',
    );
    return false;
  }

  for (var i = 0; i < 8; i++) {
    if (bytes[i] != _pngMagic[i]) {
      stderr.writeln(
        '[driver] ERROR: Screenshot "$name" lacks valid PNG signature header.',
      );
      return false;
    }
  }

  // Reject known 68-byte 1x1 placeholder artifacts (STEP-48 / RISK-0023 / RISK-0024).
  if (bytes.length == 68) {
    stderr.writeln(
      '[driver] ERROR: Screenshot "$name" is exactly 68 bytes (known 1x1 placeholder). '
      'Synthetic placeholder artifacts are forbidden by PROJECT.md.',
    );
    return false;
  }

  return true;
}

/// Resolves screenshot destination directory in priority order:
/// 1. `args['destinationDirectory']` or `args['destination_dir']`
/// 2. `SCREENSHOT_DESTINATION_DIR` or `SCREENSHOT_DIR` environment variables
/// 3. Default: `../mine-flow-docs/reports/design-review/step-0055`
String _resolveDestinationDirectory(Map<String, Object?>? args) {
  final argDir =
      (args?['destinationDirectory'] ?? args?['destination_dir']) as String?;
  if (argDir != null && argDir.trim().isNotEmpty) {
    return argDir.trim();
  }

  final envDir =
      Platform.environment['SCREENSHOT_DESTINATION_DIR'] ??
      Platform.environment['SCREENSHOT_DIR'];
  if (envDir != null && envDir.trim().isNotEmpty) {
    return envDir.trim();
  }

  return '../mine-flow-docs/reports/design-review/step-0055';
}

/// Throws a [StateError] if the destination path points to a protected historical release directory.
void _assertSafeDestination(String dir) {
  final normalized = dir.replaceAll('\\', '/').toLowerCase();
  for (final step in _protectedHistoricalSteps) {
    if (normalized.contains(step)) {
      throw StateError(
        'Hazard prevented: destination directory "$dir" targets historical release '
        'directory "$step". Overwriting prior step design review artifacts is prohibited.',
      );
    }
  }
}

/// Saves screenshot bytes safely to disk and logs output.
Future<bool> _handleScreenshot(
  String screenshotName,
  List<int> screenshotBytes, [
  Map<String, Object?>? args,
]) async {
  if (!_validateScreenshotBytes(screenshotName, screenshotBytes)) {
    return false;
  }

  final destDir = _resolveDestinationDirectory(args);
  _assertSafeDestination(destDir);

  final cleanDir = destDir.endsWith('/') || destDir.endsWith('\\')
      ? destDir.substring(0, destDir.length - 1)
      : destDir;
  final cleanName = screenshotName.endsWith('.png')
      ? screenshotName
      : '$screenshotName.png';
  final file = File('$cleanDir/$cleanName');

  await file.parent.create(recursive: true);
  await file.writeAsBytes(screenshotBytes, flush: true);

  stdout.writeln(
    '[driver] Saved screenshot: ${file.path} (${screenshotBytes.length} bytes)',
  );
  return true;
}

Future<void> main() => integrationDriver(
  onScreenshot:
      (
        String screenshotName,
        List<int> screenshotBytes, [
        Map<String, Object?>? args,
      ]) => _handleScreenshot(screenshotName, screenshotBytes, args),
);
