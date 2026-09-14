/// Domain entity encapsulating user-configurable app settings.
library;

import 'package:equatable/equatable.dart';
// Material: this file uses a Material primitive with no ForUI equivalent.
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

  /// The version of the privacy policy the user has acknowledged.
  /// 0 means none.
  final int privacyAckVersion;

  const SettingsEntity({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.privacyAckVersion = 0,
  });

  SettingsEntity copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    int? privacyAckVersion,
  }) {
    return SettingsEntity(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      privacyAckVersion: privacyAckVersion ?? this.privacyAckVersion,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale, privacyAckVersion];
}
