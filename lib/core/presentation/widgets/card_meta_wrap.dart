import 'package:flutter/widgets.dart';

/// A single icon + label metadata item shown inside a record card.
///
/// ## Why this exists (STEP-48.22 re-run, finding R-2)
/// The record cards laid their metadata out as `Row`s of icons and `Text`s with
/// no shrinkable child. Any long value (a descriptive zone name, a weather note,
/// a material type) pushed the row past the card and produced
/// `RenderFlex overflowed … on the right` — reported in CI run `33480009094` at
/// `land_clearing_card.dart:30`/`:34` and, once those `Row`s were converted to
/// `Wrap`s, at the wrapped children themselves: **a `Wrap` reflows between its
/// children but never shrinks a child that is individually too wide.**
///
/// Wrapping the label in a [Flexible] is what makes each chip shrinkable. A
/// `Wrap` passes its own `maxWidth` down to each child, so the [Flexible] has a
/// real bound to shrink against and the label ellipsises instead of overflowing.
class CardMetaChip extends StatelessWidget {
  /// Leading icon, already sized and coloured by the caller.
  final Widget icon;

  /// The label. Callers should set `overflow: TextOverflow.ellipsis`.
  final Widget label;

  /// Gap between [icon] and [label].
  final double spacing;

  const CardMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      icon,
      SizedBox(width: spacing),
      // Flexible (not Expanded) keeps the chip at its intrinsic width when it
      // fits and lets it shrink instead of overflow when it does not.
      Flexible(child: label),
    ],
  );
}

/// Lays [children] out as a wrapping run of card metadata chips.
///
/// See [CardMetaChip] for why each child must be able to shrink.
class CardMetaWrap extends StatelessWidget {
  /// The chips. Typically [CardMetaChip]s; anything shrinkable works.
  final List<Widget> children;

  /// Horizontal gap between chips in the same run.
  final double spacing;

  /// Vertical gap between runs.
  final double runSpacing;

  /// How the chips are distributed along each run.
  final WrapAlignment alignment;

  const CardMetaWrap({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 4,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: alignment,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: spacing,
    runSpacing: runSpacing,
    children: children,
  );
}
