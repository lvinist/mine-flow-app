import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';

import '../helpers/app_harness.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Journey (STEP-45.3)', () {
    testWidgets('login, session restore, logout, and invalid login E2E', (
      tester,
    ) async {
      if (!isStagingConfigured) {
        markTestSkipped('Unverified: Staging credentials absent');
        return;
      }

      final storage = SecureStorageService();
      await storage.clearAll();

      // 1. Boot the app.
      await pumpApp(tester);

      expect(find.widgetWithText(FButton, 'Masuk'), findsOneWidget);

      final emailField = find.byType(EditableText).first;
      final passwordField = find.byType(EditableText).last;

      // --- Invalid Login ---
      await tester.enterText(emailField, 'wrong@example.com');
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FButton, 'Masuk'));
      await tester.pumpAndSettle();

      // Expect to remain on login screen (Masuk button still exists).
      expect(find.widgetWithText(FButton, 'Masuk'), findsOneWidget);
      // Ensure no session was created.
      final invalidSession = await storage.getSessionData();
      expect(invalidSession['token'], isNull);
      expect(authCubit?.state.status, AuthStatus.unauthenticated);

      // --- Real Login ---
      await tester.enterText(emailField, testUserEmail);
      await tester.enterText(passwordField, testUserPassword);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FButton, 'Masuk'));
      await tester.pumpAndSettle();

      // Expect we navigated away from login screen.
      expect(find.widgetWithText(FButton, 'Masuk'), findsNothing);
      expect(authCubit?.state.status, AuthStatus.authenticated);
      expect(authCubit?.state.user, isNotNull);
      // Ensure it's the real user and not a hardcoded stub.
      expect(authCubit?.state.user?.email, equals(testUserEmail));

      // Assert session token is stored.
      final validSession = await storage.getSessionData();
      expect(validSession['token'], isNotNull);
      expect(validSession['userId'], isNotNull);

      // --- Session Restore ---
      // Re-pump the app to simulate a cold start with a valid session.
      await pumpApp(tester);

      // Expect we restore the session and skip login.
      expect(find.widgetWithText(FButton, 'Masuk'), findsNothing);
      expect(authCubit?.state.status, AuthStatus.authenticated);
      expect(authCubit?.state.user, isNotNull);

      // --- Logout ---
      await authCubit!.signOut();
      await tester.pumpAndSettle();

      // Expect we returned to the login screen.
      expect(find.widgetWithText(FButton, 'Masuk'), findsOneWidget);

      // Ensure the session was cleared.
      final clearedSession = await storage.getSessionData();
      expect(clearedSession['token'], isNull);
      expect(authCubit?.state.status, AuthStatus.unauthenticated);
    });
  });
}
