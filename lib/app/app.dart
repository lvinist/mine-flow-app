// Root application widget for mine-flow.
//
// Configures MaterialApp.router with the Forest & Stone theme (AppTheme),
// the appRouter for navigation, and the Indonesian locale per Doc 07 — UI /
// Design System §5 System Capabilities (i18n: Indonesian ID).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/app/theme/app_theme.dart';

/// The root widget of the mine-flow application.
class MineFlowApp extends StatelessWidget {
  const MineFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'mine-flow',
      debugShowCheckedModeBanner: false,

      // --- Theme (Doc 07: Forest & Stone) ---
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follow OS preference by default; user toggle is wired in STEP-4.
      themeMode: ThemeMode.system,

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
  }
}
