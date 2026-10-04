import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Keeps responsive MediaQuery dimensions aligned with a capture's logical
/// surface without forging the real device metrics used by the renderer.
///
/// IntegrationTestWidgetsFlutterBinding.setSurfaceSize changes render
/// constraints, but MediaQuery.fromView still reports the native window size.
/// Both must change together or narrow captures can paint the desktop shell
/// into phone-width constraints. The stable child preserves app state between
/// viewport changes; all other media properties remain inherited.
class CaptureViewport extends StatelessWidget {
  /// Wraps [child] in the current logical capture [size], or native size if null.
  const CaptureViewport({super.key, required this.size, required this.child});

  /// Logical size used by the integration binding; null means native metrics.
  final ValueListenable<Size?> size;

  /// Stable application subtree; resizing must not recreate its providers.
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Size?>(
    valueListenable: size,
    child: child,
    builder: (context, logicalSize, child) {
      final inherited = MediaQuery.of(context);
      return MediaQuery(
        data: inherited.copyWith(size: logicalSize ?? inherited.size),
        child: child!,
      );
    },
  );
}
