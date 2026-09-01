import 'package:flutter/widgets.dart';

/// A sliver that lays out record cards at their **content height** in one or
/// two columns.
///
/// ## Why this exists (STEP-48.22 re-run, finding R-2)
/// The daily-log, cut/fill, and land-clearing list screens each built a
/// `SliverGrid` with `SliverGridDelegateWithFixedCrossAxisCount` and a fixed
/// `childAspectRatio` (`3.2` mobile / `2.6` wide). A fixed aspect ratio forces a
/// fixed tile height, so any card whose content is taller than that tile
/// overflows — which is exactly what CI run `33480009094` reported as
/// `RenderFlex overflowed by 80 pixels on the bottom` at `cut_fill_card.dart:33`
/// and `58 pixels` at `land_clearing_card.dart:30`. Card content is variable by
/// nature (optional zone, material type, elevation, notes, delete affordance),
/// so no single ratio is correct at every breakpoint and text scale.
///
/// This widget keeps the layout Doc 07 describes — a single column on phones, two
/// columns once there is room — while letting each row size to its content, so
/// the overflow class cannot recur when a card grows a line.
///
/// Cards in a two-column row are stretched to equal height via [IntrinsicHeight]
/// so the grid still reads as a grid rather than a ragged pair of columns.
class AdaptiveCardSliverGrid extends StatelessWidget {
  /// Number of columns. Values above 2 are clamped to 2 (the design system's
  /// widest record-list layout).
  final int crossAxisCount;

  /// Total number of cards.
  final int itemCount;

  /// Builds the card at [index].
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Padding around the whole list.
  final EdgeInsetsGeometry padding;

  /// Vertical gap between rows.
  final double mainAxisSpacing;

  /// Horizontal gap between the two columns.
  final double crossAxisSpacing;

  const AdaptiveCardSliverGrid({
    super.key,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final columns = crossAxisCount.clamp(1, 2);
    final rowCount = (itemCount / columns).ceil();

    return SliverPadding(
      padding: padding,
      sliver: SliverList.builder(
        itemCount: rowCount,
        itemBuilder: (context, rowIndex) {
          final isLastRow = rowIndex == rowCount - 1;
          final bottomGap = isLastRow ? 0.0 : mainAxisSpacing;

          if (columns == 1) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomGap),
              child: itemBuilder(context, rowIndex),
            );
          }

          final firstIndex = rowIndex * columns;
          final secondIndex = firstIndex + 1;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomGap),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: itemBuilder(context, firstIndex)),
                  SizedBox(width: crossAxisSpacing),
                  Expanded(
                    child: secondIndex < itemCount
                        ? itemBuilder(context, secondIndex)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
