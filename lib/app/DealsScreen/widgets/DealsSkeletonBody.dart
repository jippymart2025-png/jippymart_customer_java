import 'package:flutter/material.dart';

import '../../../core/responsive.dart';
import 'appbar.dart';

/// Shared shimmer animation for skeleton placeholders.
mixin _ShimmerMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController shimmerCtrl;
  late Animation<double> shimmerAnim;

  Color get shimmerBase => const Color(0xFFEDE8F8);

  Color get shimmerLight => const Color(0xFFD9D3F0);

  Color get shimmerColor =>
      Color.lerp(shimmerBase, shimmerLight, shimmerAnim.value)!;

  @override
  void initState() {
    super.initState();
    shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    shimmerAnim = CurvedAnimation(parent: shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    shimmerCtrl.dispose();
    super.dispose();
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width, height, radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin, _ShimmerMixin {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: shimmerAnim,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: shimmerColor,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

class _SkeletonRestaurantCard extends StatefulWidget {
  const _SkeletonRestaurantCard({required this.rs});

  final Responsive rs;

  @override
  State<_SkeletonRestaurantCard> createState() =>
      _SkeletonRestaurantCardState();
}

class _SkeletonRestaurantCardState extends State<_SkeletonRestaurantCard>
    with SingleTickerProviderStateMixin, _ShimmerMixin {
  @override
  Widget build(BuildContext context) {
    final rs = widget.rs;
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (_, __) {
        final c = shimmerColor;
        return Container(
          margin: EdgeInsets.fromLTRB(rs.hPad, 0, rs.hPad, 14),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: C.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F2D1B4E),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 13,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 100,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: rs.prodScrollH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, __) => Container(
                    width: rs.cardWidth,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-screen skeleton shown while the deals screen is loading, or
/// while waiting for the delivery zone to resolve.
class DealsSkeletonBody extends StatelessWidget {
  const DealsSkeletonBody({super.key, required this.rs});

  final Responsive rs;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(rs.hPad, 14, rs.hPad, 0),
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8F8),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(rs.hPad, 20, rs.hPad, 10),
            child: const _SkeletonBox(width: 180, height: 16),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => _SkeletonRestaurantCard(rs: rs),
            childCount: 2,
          ),
        ),
      ],
    );
  }
}
