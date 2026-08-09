/// Local (Hive-backed) persistence for user settings (theme & locale).
library;

import 'package:hive/hive.dart';

/// Persistence layer for user preference key-value pairs.
///
/// Stores settings in a single Hive box (`settings_box`) as a flat
/// `Map<String, dynamic>` with two keys: `themeMode` (int index) and
/// `locale` (string language code).
class SettingsLocalDataSource {
  static const _boxName = 'settings_box';

  static const _themeModeKey = 'themeMode';
  static const _localeKey = 'locale';

  Box? _box;

  /// Ensures the Hive box is open.
  Future<Box> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }

  /// Reads the stored theme mode index, or null if never saved.
  Future<int?> getThemeModeIndex() async {
    final box = await _ensureBox();
    return box.get(_themeModeKey) as int?;
  }

  /// Persists the theme mode index.
  Future<void> saveThemeModeIndex(int index) async {
    final box = await _ensureBox();
    await box.put(_themeModeKey, index);
  }

  /// Reads the stored locale language code (e.g., `'en'`, `'id'`),
  /// or null if never saved.
  Future<String?> getLocaleCode() async {
    final box = await _ensureBox();
    return box.get(_localeKey) as String?;
  }

  /// Persists the locale language code.
  Future<void> saveLocaleCode(String code) async {
    final box = await _ensureBox();
    await box.put(_localeKey, code);
  }

  /// Clears all stored settings (useful for reset-to-default).
  Future<void> clear() async {
    final box = await _ensureBox();
    await box.clear();
  }
}
