import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:jippymart_customer/app/home_screen/screen/category_restaurant_screen/provider/category_resaurant_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/widget/restaurant_image_view.dart';

import '../../../../themes/app_them_data.dart';

class CategoryRestaurantScreen extends StatefulWidget {
  const CategoryRestaurantScreen({super.key});

  @override
  State<CategoryRestaurantScreen> createState() =>
      _CategoryRestaurantScreenState();
}

class _CategoryRestaurantScreenState extends State<CategoryRestaurantScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryRestaurantProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppThemeData.pageBg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  categoryName:
                      controller.vendorCategoryModel.title ?? 'Restaurants',
                  count: controller.allNearestRestaurant.length,
                ),
              ),

              if (controller.isLoading)
                const SliverFillRemaining(child: Center(child: _LoadingView()))
              else if (controller.allNearestRestaurant.isEmpty)
                const SliverFillRemaining(child: _EmptyView())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final vendor = controller.allNearestRestaurant[index];
                      return _AnimatedCard(
                        index: index,
                        child: _RestaurantCard(
                          vendor: vendor,
                          onTap: () {
                            context
                                .read<RestaurantDetailsProvider>()
                                .initFunction(vendorModels: vendor);
                            Get.to(
                              const RestaurantDetailsScreen(),
                              arguments: {'vendorModel': vendor},
                            );
                          },
                        ),
                      );
                    }, childCount: controller.allNearestRestaurant.length),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Sticky header delegate
// ─────────────────────────────────────────────
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String categoryName;
  final int count;

  const _StickyHeaderDelegate({
    required this.categoryName,
    required this.count,
  });

  @override
  double get minExtent => 140;

  @override
  double get maxExtent => 140;

  @override
  bool shouldRebuild(_StickyHeaderDelegate old) =>
      old.count != count || old.categoryName != categoryName;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white, // ✅ pure white background
      child: SafeArea(
        // ✅ handles notch / status bar
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),

              // ── Top row ──────────────────────────────────────
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Get.back(),
                    bgColor: AppThemeData.cardBg,
                    iconColor: AppThemeData.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontFamily: AppThemeData.fontBold,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppThemeData.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$count restaurants nearby',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppThemeData.textMuted,
                            fontFamily: AppThemeData.fontMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(width: 12),
                  // _CircleIconButton(
                  //   icon: Icons.tune_rounded,
                  //   onTap: () {},
                  //   bgColor: AppThemeData.orange,
                  //   iconColor: Colors.white,
                  // ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Sort row ─────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Sorted by distance',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppThemeData.textMuted,
                      fontFamily: AppThemeData.fontMedium,
                    ),
                  ),
                  // const Spacer(),
                  // GestureDetector(
                  //   onTap: () {},
                  //   child: const Text(
                  //     'Change ›',
                  //     style: TextStyle(
                  //       fontSize: 13,
                  //       color: AppThemeData.orange,
                  //       fontFamily: AppThemeData.fontSemiBold,
                  //       fontWeight: FontWeight.w700,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Restaurant card
// ─────────────────────────────────────────────
class _RestaurantCard extends StatefulWidget {
  final VendorModel vendor;
  final VoidCallback onTap;

  const _RestaurantCard({required this.vendor, required this.onTap});

  @override
  State<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<_RestaurantCard>
    with SingleTickerProviderStateMixin {
  bool _isFav = false;
  late final AnimationController _hoverCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  bool get _isOpen => widget.vendor.isOpen == true;

  bool get _isFreeDelivery =>
      widget.vendor.isSelfDelivery == true &&
      Constant.isSelfDeliveryFeature == true;

  String get _rating => Constant.calculateReview(
    reviewCount: widget.vendor.reviewsCount?.toStringAsFixed(0) ?? '0',
    reviewSum: widget.vendor.reviewsSum?.toString() ?? '0',
  );

  String get _distance =>
      '${Constant.getDistanceFromVendor(widget.vendor)} ${Constant.distanceType}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) {
        _hoverCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: AppThemeData.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image section ─────────────────────────────
              _CardImage(
                vendor: widget.vendor,
                isFav: _isFav,
                isOpen: _isOpen,
                isFreeDelivery: _isFreeDelivery,
                rating: _rating,
                distance: _distance,
                onFavTap: () => setState(() => _isFav = !_isFav),
              ),

              // ── Offer strip (show if applicable) ─────────
              // if (_isFreeDelivery || widget.vendor.discount != null)
              //   _OfferStrip(
              //     text: widget.vendor.discount != null
              //         ? widget.vendor.discount.toString()
              //         : 'Free delivery on this order',
              //   ),

              // ── Text body ─────────────────────────────────
              _CardBody(vendor: widget.vendor),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Card image with overlays
// ─────────────────────────────────────────────
class _CardImage extends StatelessWidget {
  final VendorModel vendor;
  final bool isFav;
  final bool isOpen;
  final bool isFreeDelivery;
  final String rating;
  final String distance;
  final VoidCallback onFavTap;

  const _CardImage({
    required this.vendor,
    required this.isFav,
    required this.isOpen,
    required this.isFreeDelivery,
    required this.rating,
    required this.distance,
    required this.onFavTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Restaurant image
            RestaurantImageView(vendorModel: vendor),

            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0A0804)],
                  stops: [0.35, 1.0],
                ),
              ),
            ),

            // Favourite button — top left
            Positioned(
              top: 12,
              left: 12,
              child: GestureDetector(
                onTap: onFavTap,
                child: _GlassChip(
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 15,
                    color: isFav ? AppThemeData.orange : Colors.white,
                  ),
                ),
              ),
            ),

            // Open / closed badge — top right
            Positioned(
              top: 12,
              right: 12,
              child: _GlassChip(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOpen ? AppThemeData.green : AppThemeData.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOpen ? 'Open' : 'Closed',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: AppThemeData.fontSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom badges row
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  if (isFreeDelivery) ...[
                    _GlassChip(
                      borderColor: const Color(0x801DB954),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.delivery_dining_rounded,
                            size: 13,
                            color: Color(0xFF4ADE80),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Free delivery',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4ADE80),
                              fontFamily: AppThemeData.fontSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _GlassChip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: AppThemeData.fontSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _GlassChip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 13,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: AppThemeData.fontSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Glassmorphism chip (used on top of images)
// ─────────────────────────────────────────────
class _GlassChip extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _GlassChip({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.28),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Offer strip
// ─────────────────────────────────────────────
class _OfferStrip extends StatelessWidget {
  final String text;

  const _OfferStrip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppThemeData.orangeLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_rounded,
            size: 14,
            color: AppThemeData.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppThemeData.orange,
                fontFamily: AppThemeData.fontSemiBold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Card body (name, cuisine, meta row)
// ─────────────────────────────────────────────
class _CardBody extends StatelessWidget {
  final VendorModel vendor;

  const _CardBody({required this.vendor});

  // String get _priceSymbol {
  //   final avg = vendor.averagePrice ?? 0;
  //   if (avg < 150) return '₹';
  //   if (avg < 400) return '₹₹';
  //   return '₹₹₹';
  // }

  // String get _deliveryTime =>
  //     vendor.deliveryTime != null ? '${vendor.deliveryTime} min' : '-- min';
  //
  // String get _deliveryFee =>
  //     (vendor.deliveryCharge != null && vendor.deliveryCharge! > 0)
  //     ? '₹${vendor.deliveryCharge!.toStringAsFixed(0)}'
  //     : '₹0';
  //
  // String get _minOrder => vendor.minOrderPrice != null
  //     ? '₹${vendor.minOrderPrice!.toStringAsFixed(0)}'
  //     : '--';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + price tier
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  vendor.title ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppThemeData.fontBold,
                    color: AppThemeData.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                // child: Text(
                //   _priceSymbol,
                //   style: const TextStyle(
                //     fontSize: 12,
                //     fontFamily: AppThemeData.fontSemiBold,
                //     color: AppThemeData.textMuted,
                //   ),
                // ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Cuisine tags
          // if (vendor.cuisines != null && vendor.cuisines!.isNotEmpty)
          //   Text(
          //     vendor.cuisines!.take(3).join(' · '),
          //     style: const TextStyle(
          //       fontSize: 12,
          //       color: AppThemeData.textMuted,
          //       fontFamily: AppThemeData.fontMedium,
          //     ),
          //     maxLines: 1,
          //     overflow: TextOverflow.ellipsis,
          //   ),

          // Divider
          // Container(
          //   margin: const EdgeInsets.symmetric(vertical: 12),
          //   height: 1,
          //   color: AppThemeData.divider,
          // ),

          // Meta row: delivery time | fee | min order
          // IntrinsicHeight(
          //   child: Row(
          //     children: [
          //       _MetaItem(
          //         value: _deliveryTime,
          //         label: 'Delivery',
          //         valueColor: vendor.isOpen == true ? AppThemeData.textPrimary : AppThemeData.red,
          //       ),
          //       _VerticalDivider(),
          //       _MetaItem(value: _deliveryFee, label: 'Del. fee'),
          //       _VerticalDivider(),
          //       _MetaItem(value: _minOrder, label: 'Min. order'),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _MetaItem({
    required this.value,
    required this.label,
    this.valueColor = AppThemeData.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: AppThemeData.fontSemiBold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppThemeData.textLight,
              fontFamily: AppThemeData.fontSemiBold,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: AppThemeData.divider);
  }
}

// ─────────────────────────────────────────────
//  Circle icon button (back + filter)
// ─────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;
  final Color iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: bgColor == AppThemeData.cardBg
              ? [
                  const BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Loading shimmer
// ─────────────────────────────────────────────
class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: 3,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ShimmerCard(animation: _anim),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final Animation<double> animation;

  const _ShimmerCard({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final shimmerColor = Color.lerp(
          const Color(0xFFF0EDE8),
          const Color(0xFFE4E1DB),
          animation.value,
        )!;
        return Container(
          decoration: BoxDecoration(
            color: AppThemeData.cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 168,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: 180,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(
                        3,
                        (_) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 36,
                            decoration: BoxDecoration(
                              color: shimmerColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppThemeData.cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_outlined,
                size: 36,
                color: AppThemeData.textLight,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No restaurants found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: AppThemeData.fontBold,
                color: AppThemeData.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing your location or adjusting the filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppThemeData.textMuted,
                fontFamily: AppThemeData.fontMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppThemeData.orange,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Go back',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppThemeData.fontSemiBold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
