import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../integration_test/helpers/capture_viewport.dart';

/// Pins the logical/native metric split that broke the real capture matrix.
void main() {
  testWidgets(
    'capture size updates MediaQuery without remounting application',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final size = ValueNotifier<Size?>(null);
      addTearDown(size.dispose);
      var mounts = 0;
      await tester.pumpWidget(
        CaptureViewport(
          size: size,
          child: MaterialApp(home: _Probe(onMount: () => mounts++)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1400.0x1000.0'), findsOneWidget);
      size.value = const Size(400, 800);
      await tester.pump();
      expect(find.text('400.0x800.0'), findsOneWidget);
      expect(tester.view.physicalSize, const Size(1400, 1000));
      size.value = const Size(700, 1000);
      await tester.pump();
      expect(find.text('700.0x1000.0'), findsOneWidget);
      size.value = null;
      await tester.pump();
      expect(find.text('1400.0x1000.0'), findsOneWidget);
      expect(mounts, 1);
    },
  );
}

/// Stateful descendant proving viewport changes preserve providers/state.
class _Probe extends StatefulWidget {
  const _Probe({required this.onMount});
  final VoidCallback onMount;

  @override
  State<_Probe> createState() => _ProbeState();
}

/// Reports inherited metrics rather than the physical test window.
class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Text('${size.width}x${size.height}');
  }
}
