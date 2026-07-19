// Theme Cubit — manages dark/light mode toggle state.
//
// Persists the user's preference via Hive in a later STEP; for now it defaults
// to system preference with a manual toggle. The UI toggle button calls
// [toggleTheme] and the consuming widget rebuilds via BlocBuilder.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Theme state — carries the current [ThemeMode].
class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({this.themeMode = ThemeMode.system});

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }
}

/// Cubit that toggles between system, light, and dark theme modes.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  void toggleTheme() {
    emit(
      state.copyWith(
        themeMode: state.themeMode == ThemeMode.dark
            ? ThemeMode.light
            : ThemeMode.dark,
      ),
    );
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }
}
