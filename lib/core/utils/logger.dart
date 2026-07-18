// Centralized logger factory for mine-flow.
//
// Uses the `logging` package as required by the Dart coding standard
// (mine-flow-docs/coding-standards/dart.md, §Logging). Call buildLogger to
// get a named Logger instance in each class.
//
// The root logger is configured once in configureLogging, called from
// main. Log output goes to the console during debug builds; in release
// builds the level threshold filters out verbose messages automatically.

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Configures the root [Logger] for the application.
///
/// Must be called once during app initialisation, before any logger is used.
/// In debug builds all log levels are shown; in release builds only WARNING
/// and above are emitted to avoid leaking internal state.
void configureLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((record) {
    // In release builds only WARNING+ reaches here due to the level filter above.
    // Never log secrets or PII (see Dart coding standard §Logging).
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}'
      '${record.error != null ? '\n${record.error}' : ''}'
      '${record.stackTrace != null ? '\n${record.stackTrace}' : ''}',
    );
  });
}

/// Returns a [Logger] scoped to [name].
///
/// Usage:
/// ```dart
/// final _log = buildLogger('MyClass');
/// _log.info('doing something');
/// _log.warning('something went wrong', error, stackTrace);
/// ```
Logger buildLogger(String name) => Logger(name);
