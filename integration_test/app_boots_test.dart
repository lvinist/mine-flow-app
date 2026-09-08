import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and shows login screen', (WidgetTester tester) async {
    if (!isStagingConfigured) {
      recordE2eSkipped('app_boots_test.dart: staging credentials absent');
      markTestSkipped('Unverified: Staging credentials absent');
      return;
    }

    recordE2eExecuted('app_boots');

    await pumpApp(tester);

    // Verify that the login screen is rendered.
    // Targeting EditableText instead of TextField to avoid forui semantics regression (RISK-0009).
    expect(find.byType(EditableText), findsWidgets);
  });
}
