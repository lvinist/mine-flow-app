// Smoke test — verifies that the app widget tree renders without crashing.
//
// This does not test any business logic (those live in feature test files).
// It simply ensures MineFlowApp can be pumped and basic widgets appear,
// which catches import errors and obvious startup crashes in CI.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/app/app.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'mine_flow_widget_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('app launches without crashing', (WidgetTester tester) async {
    // Pump the root app widget.
    await tester.pumpWidget(const MineFlowApp());
    await tester.pumpAndSettle();

    // The router should render something (at minimum a Scaffold or text).
    // A more specific assertion will be added in STEP-3 when the login screen
    // has real content.
    expect(find.byType(MineFlowApp), findsOneWidget);
  });
}
