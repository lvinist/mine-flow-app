import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'staging_config.dart';

/// Logs in as a staging user with the given role.
/// Roles are wired in 45.12; currently stubbed to use the default staging credentials.
Future<void> loginAsStagingUser(
  WidgetTester tester, {
  String role = 'supervisor',
}) async {
  if (!isStagingConfigured) {
    return;
  }

  // Target EditableText finders due to RISK-0009 (flutter/flutter#191095 semantics regression on 3.47).
  final emailField = find.byType(EditableText).first;
  final passwordField = find.byType(EditableText).last;

  String email = testUserEmail;
  String password = testUserPassword;

  if (hasPerRoleAccounts) {
    if (role == 'foreman') {
      email = testForemanEmail;
      password = testForemanPassword;
    } else if (role == 'supervisor') {
      email = testSupervisorEmail;
      password = testSupervisorPassword;
    }
  }

  await tester.enterText(emailField, email);
  await tester.enterText(passwordField, password);
  await tester.pumpAndSettle();

  final submitButton = find.widgetWithText(FButton, 'Masuk');
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}
