// Root application widget for mine-flow.
//
// Configures MaterialApp.router with the Forest & Stone theme (AppTheme),
// the appRouter for navigation, and the Indonesian locale per Doc 07 — UI /
// Design System §5 System Capabilities (i18n: Indonesian ID).
//
// Theme toggle is driven by ThemeCubit (via BlocProvider), allowing the
// responsive AppShell's toggle button to switch light/dark mode at runtime.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
          return MaterialApp.router(
            title: 'mine-flow',
            debugShowCheckedModeBanner: false,

            // --- Theme (Doc 07: Forest & Stone) ---
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            // Driven by ThemeCubit toggle; defaults to system.
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
          );
        },
      ),
    );
  }
}
