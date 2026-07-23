import 'package:flutter/material.dart';

/// A grid that adds columns automatically as the available width
/// grows, so cards that look right as a single stacked column on a
/// phone become a 2-3 column grid on tablet/desktop — instead of one
/// card stretching edge-to-edge on a wide screen.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double maxCrossAxisExtent;
  final double mainAxisExtent;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.maxCrossAxisExtent,
    required this.mainAxisExtent,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        mainAxisExtent: mainAxisExtent,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}
