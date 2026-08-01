/// Implementation of [SettingsRepository] backed by [SettingsLocalDataSource].
library;

import 'package:flutter/material.dart';
import 'package:mine_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';

/// Concrete repository that delegates persistence to [SettingsLocalDataSource].
///
/// Converts between raw Hive values (int, String) and Flutter types
/// ([ThemeMode], [Locale]).
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl({required this._localDataSource});

  @override
  Future<ThemeMode> getThemeMode() async {
    final index = await _localDataSource.getThemeModeIndex();
    if (index == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (mode) => mode.index == index,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _localDataSource.saveThemeModeIndex(mode.index);
  }

  @override
  Future<Locale> getLocale() async {
    final code = await _localDataSource.getLocaleCode();
    if (code == null) return const Locale('en');
    return Locale(code);
  }

  @override
  Future<void> saveLocale(Locale locale) async {
    await _localDataSource.saveLocaleCode(locale.languageCode);
  }
}
