// Application entry point for mine-flow.
//
// Initialises core services before launching the widget tree:
//   1. Flutter engine bindings
//   2. Logging (structured, level-filtered — see core/utils/logger.dart)
//   3. Hive local database (ADR-0001: selected over SQLite/sqflite)
//   4. Supabase SDK (credentials injected via --dart-define at build time)
//
// Secrets are NOT stored in this file. They are injected at build time via
// `--dart-define` flags from GitHub Actions Secrets or a local `.env` file.
// See Doc 09 — Environments §2 Configuration & Secrets and `.env.example`.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mine_flow/app/app.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/core/init/app_initializer.dart';
import 'package:mine_flow/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global reference to initialised app services.
///
/// Used by route builders in `router.dart` until a proper DI container
/// (e.g. GetIt) replaces this in STEP-10.
AppServices? appServices;

final _log = buildLogger('main');

Future<void> main() async {
  // 1. Flutter engine must be initialised before any platform channel calls.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Configure structured logging before any other initialisation so that
  //    setup errors are captured.
  configureLogging();
  _log.info('Starting mine-flow (env: $appEnv)');

  // 3. Initialise Hive local database (ADR-0001).
  //    Hive stores offline records and the sync queue on the device.
  await Hive.initFlutter();
  _log.info('Hive initialised');

  // 4. Initialise Supabase with credentials injected at build time.
  //    supabaseUrl and supabaseAnonKey are empty strings when the app is run
  //    without dart-define flags — the app will show an error state in that case.
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey, // ignore: deprecated_member_use
  );
  _log.info('Supabase initialised');

  // 5. Initialise core services and register feature sync handlers.
  final initializer = AppInitializer();
  appServices = await initializer.initialize();
  _log.info('App services initialised — sync registrars registered');

  runApp(const MineFlowApp());
}
