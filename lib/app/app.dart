// Root application widget for mine-flow.
//
// Configures MaterialApp.router with ForUI FTheme (FTheme.neutral),
// the appRouter for navigation, and the Indonesian locale per Doc 07 — UI /
// Design System §5 System Capabilities (i18n: Indonesian ID).
//
// Theme toggle is driven by ThemeCubit (via BlocProvider), allowing the
// responsive AppShell's toggle button to switch light/dark mode at runtime.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/app/presentation/bloc/theme_cubit.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/app/theme/app_theme.dart';

/// The root widget of the mine-flow application.
class MineFlowApp extends StatelessWidget {
  const MineFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final isDark = themeState.themeMode == ThemeMode.dark;
          final fThemeData = isDark ? FTheme.neutral.dark.touch : FTheme.neutral.light.touch;

          return FTheme(
            data: fThemeData,
            child: MaterialApp.router(
              title: 'mine-flow',
              debugShowCheckedModeBanner: false,

              // --- Material Theme baseline (for fallback material routing components) ---
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeState.themeMode,

              // --- Router (go_router) ---
              routerConfig: appRouter,

              // --- Localization (Doc 07: Indonesian (ID) default) ---
              locale: const Locale('id', 'ID'),
              supportedLocales: const [
                Locale('id', 'ID'), // Indonesian — primary
                Locale('en', 'US'), // English — fallback
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // Wrap descendant tree in FTheme to guarantee ForUI theme availability across routes
              builder: (context, child) {
                return FTheme(
                  data: fThemeData,
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
