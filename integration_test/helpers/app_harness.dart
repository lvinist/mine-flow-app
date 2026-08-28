import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mine_flow/app/app.dart';
import 'package:mine_flow/core/init/app_initializer.dart';
import 'package:mine_flow/core/utils/logger.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mine_flow/main.dart' as app_main;

import 'staging_config.dart';

/// Boots the real app widget for integration testing.
/// Mirrors main.dart initialization: logging, Hive, Supabase from --dart-define.
Future<void> pumpApp(WidgetTester tester) async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  configureLogging();

  await Hive.initFlutter();

  if (isStagingConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey, // ignore: deprecated_member_use
    );
  }

  final initializer = AppInitializer();
  app_main.appServices = await initializer.initialize();

  authCubit = AuthCubit(repository: app_main.appServices!.authRepository);
  await authCubit!.initialize();

  await tester.pumpWidget(const MineFlowApp());
  await tester.pumpAndSettle();
}
