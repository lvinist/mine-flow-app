/// Unit tests for [SettingsRepositoryImpl].
///
/// Tests the conversion between raw Hive values (int, String) and Flutter types
/// ([ThemeMode], [Locale]) via the mocked [SettingsLocalDataSource].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:mine_flow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';

/// A mock [SettingsLocalDataSource] that stores values in memory.
///
/// Mirrors the real datasource contract but avoids Hive IO — suitable for
/// fast, deterministic unit tests.
class MockSettingsLocalDataSource extends SettingsLocalDataSource {
  int? _storedThemeIndex;
  String? _storedLocaleCode;

  @override
  Future<int?> getThemeModeIndex() async => _storedThemeIndex;

  @override
  Future<void> saveThemeModeIndex(int index) async {
    _storedThemeIndex = index;
  }

  @override
  Future<String?> getLocaleCode() async => _storedLocaleCode;

  @override
  Future<void> saveLocaleCode(String code) async {
    _storedLocaleCode = code;
  }

  @override
  Future<void> clear() async {
    _storedThemeIndex = null;
    _storedLocaleCode = null;
  }
}

void main() {
  late MockSettingsLocalDataSource mockDataSource;
  late SettingsRepository repository;

  setUp(() {
    mockDataSource = MockSettingsLocalDataSource();
    repository = SettingsRepositoryImpl(localDataSource: mockDataSource);
  });

  group('SettingsRepository', () {
    // ====================================================================
    // Theme mode
    // ====================================================================

    test('getThemeMode returns ThemeMode.system when nothing stored', () async {
      final result = await repository.getThemeMode();
      expect(result, equals(ThemeMode.system));
    });

    test('saveThemeMode and getThemeMode round-trips correctly', () async {
      await repository.saveThemeMode(ThemeMode.dark);
      final result = await repository.getThemeMode();
      expect(result, equals(ThemeMode.dark));
    });

    test('saveThemeMode and getThemeMode round-trips light', () async {
      await repository.saveThemeMode(ThemeMode.light);
      final result = await repository.getThemeMode();
      expect(result, equals(ThemeMode.light));
    });

    test('getThemeMode falls back to system for unknown index', () async {
      // Inject an invalid index directly into the mock
      await mockDataSource.saveThemeModeIndex(99);
      final result = await repository.getThemeMode();
      expect(result, equals(ThemeMode.system));
    });

    // ====================================================================
    // Locale
    // ====================================================================

    test('getLocale returns en when nothing stored', () async {
      final result = await repository.getLocale();
      expect(result, equals(const Locale('en')));
    });

    test('saveLocale and getLocale round-trips English', () async {
      await repository.saveLocale(const Locale('en'));
      final result = await repository.getLocale();
      expect(result, equals(const Locale('en')));
    });

    test('saveLocale and getLocale round-trips Indonesian', () async {
      await repository.saveLocale(const Locale('id'));
      final result = await repository.getLocale();
      expect(result, equals(const Locale('id')));
    });
  });
}
