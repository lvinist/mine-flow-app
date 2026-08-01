/// Repository abstraction for user settings (theme & locale).
library;

import 'package:flutter/material.dart';

/// Contract for persisting and retrieving user preferences.
///
/// Settings are purely client-side (no remote sync), stored locally via Hive.
abstract class SettingsRepository {
  /// Returns the saved theme mode, or [ThemeMode.system] if none is stored.
  Future<ThemeMode> getThemeMode();

  /// Persists the given [mode] as the user's theme preference.
  Future<void> saveThemeMode(ThemeMode mode);

  /// Returns the saved locale (language), or `const Locale('en')` if none is
  /// stored.
  Future<Locale> getLocale();

  /// Persists the given [locale] as the user's language preference.
  Future<void> saveLocale(Locale locale);
}
