// Diagnostic-turned-regression coverage for the ForUI combobox affordance that
// STEP-48.22 introduced at the cut/fill material-type field.
//
// Context (STEP-48.26 residual failure R-7, assigned to 48.21): after 48.22
// replaced the Material `DropdownButtonFormField` with `CreatableCombobox`, the
// cut/fill journey's `tap(find.text('Pilih tipe material'))` stopped opening the
// option list — the tap resolved to `_RenderInkFeatures` and the `OB / Waste`
// semantics item never mounted.
//
// 48.26 asked for a diagnosis before the journey is edited: is the journey
// interacting wrongly, or can the widget genuinely not be opened by tapping its
// visible hint? These tests answer that at the widget level. Whatever the answer,
// the assertion below is the contract the journey depends on: tapping the field's
// visible text must reveal the options.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';

void main() {
  const options = ['OB / Waste', 'Soil', 'Limonite'];

  Widget wrap({ValueChanged<String>? onChanged}) => FTheme(
    data: FTheme.neutral.light.touch,
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: CreatableCombobox<String>(
            items: options,
            labelBuilder: (value) => value,
            hint: 'Pilih tipe material',
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );

  testWidgets('tapping the hint text opens the option list (R-7)', (
    tester,
  ) async {
    // `find.bySemanticsLabel` needs a live semantics tree. The integration
    // binding builds one; a plain widget test must ask for it, and must dispose
    // the handle inside the body — the framework's leak check runs before
    // tearDowns.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(
      find.text('Pilih tipe material'),
      findsOneWidget,
      reason: 'the hint is the only visible label before a selection',
    );
    // The options must not be mounted before the field is opened.
    expect(find.bySemanticsLabel('OB / Waste'), findsNothing);

    // warnIfMissed: the hint Text does not own the hit — the field's opaque
    // GestureDetector absorbs it. That absorption IS the fix; before it, the tap
    // reached the enclosing Material's ink layer and nothing opened.
    await tester.tap(find.text('Pilih tipe material'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('OB / Waste'),
      findsOneWidget,
      reason:
          'tapping the visible hint must open the list — this is what the '
          'cut/fill journey does and what regressed in run 33480009094',
    );

    semantics.dispose();
  });

  testWidgets('selecting an option reports it to onChanged (R-7)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    String? selected;
    await tester.pumpWidget(wrap(onChanged: (value) => selected = value));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih tipe material'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('OB / Waste'));
    await tester.pumpAndSettle();

    expect(selected, 'OB / Waste');

    semantics.dispose();
  });
}
