import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders ForUI widgets (FCard, FTextField, FButton)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: const MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    expect(find.byType(FCard), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.byType(FButton), findsNWidgets(2));
    expect(find.text('mine-flow'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
