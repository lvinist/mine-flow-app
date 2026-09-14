/// Cubit for managing settings state (theme & locale).
///
/// Loads persisted preferences from [SettingsRepository] on creation and
/// exposes [updateThemeMode] / [updateLocale] to mutate and persist changes.
/// This cubit supersedes the earlier [ThemeCubit] by owning both theme *and*
/// locale state in one place.
library;

// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/settings/domain/entities/settings_entity.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';

/// State exposed by [SettingsCubit].
class SettingsState {
  /// The current theme mode (system / light / dark).
  final ThemeMode themeMode;

  /// The current locale (language) selection.
  final Locale locale;

  /// The version of the privacy policy the user has acknowledged.
  final int privacyAckVersion;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.privacyAckVersion = 0,
  });

  /// Convenience getter for the domain [SettingsEntity].
  SettingsEntity get settings => SettingsEntity(
    themeMode: themeMode,
    locale: locale,
    privacyAckVersion: privacyAckVersion,
  );

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    int? privacyAckVersion,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      privacyAckVersion: privacyAckVersion ?? this.privacyAckVersion,
    );
  }
}

/// Cubit that manages theme and locale preferences, persisting changes via
/// [SettingsRepository].
///
/// On creation it loads the saved preferences from the repository so that
/// the app honours the user's last choices immediately (before any UI toggle).
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit({required this._repository}) : super(const SettingsState()) {
    _load();
  }

  /// Reads persisted preferences from the repository and emits them as the
  /// current state.
  Future<void> _load() async {
    final themeMode = await _repository.getThemeMode();
    final locale = await _repository.getLocale();
    final privacyAckVersion = await _repository.getPrivacyAckVersion();
    if (!isClosed) {
      emit(
        SettingsState(
          themeMode: themeMode,
          locale: locale,
          privacyAckVersion: privacyAckVersion,
        ),
      );
    }
  }

  /// Updates the theme mode, persists it, and emits the new state.
  Future<void> updateThemeMode(ThemeMode mode) async {
    await _repository.saveThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  /// Updates the locale, persists it, and emits the new state.
  Future<void> updateLocale(Locale locale) async {
    await _repository.saveLocale(locale);
    emit(state.copyWith(locale: locale));
  }

  /// Updates the privacy acknowledgement version, persists it, and emits the new state.
  Future<void> updatePrivacyAckVersion(int version) async {
    await _repository.savePrivacyAckVersion(version);
    emit(state.copyWith(privacyAckVersion: version));
  }
}
