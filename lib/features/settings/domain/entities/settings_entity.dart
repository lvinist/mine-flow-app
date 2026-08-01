/// Domain entity encapsulating user-configurable app settings.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// User preferences for theme and locale.
///
/// Persisted locally via Hive; no sync with Supabase since these are
/// client-side only settings.
class SettingsEntity extends Equatable {
  /// The current theme mode selection.
  final ThemeMode themeMode;

  /// The current locale (language) selection.
  ///
  /// Supported values: `const Locale('en')` (English, default) and
  /// `const Locale('id')` (Indonesian).
  final Locale locale;

  const SettingsEntity({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
  });

  SettingsEntity copyWith({ThemeMode? themeMode, Locale? locale}) {
    return SettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale];
}
