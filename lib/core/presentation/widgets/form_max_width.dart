import 'package:flutter/widgets.dart';

/// Constrains form content to a centered max width on wide layouts (CF-081).
///
/// The desktop shell spans the full viewport, so full-width submit buttons and
/// form fields stretch unreadably. Wrap a form's content in this to cap it at
/// a comfortable reading width and center it.
class FormMaxWidth extends StatelessWidget {
  /// Maximum content width in logical pixels.
  static const double maxWidth = 600;

  final Widget child;

  const FormMaxWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
