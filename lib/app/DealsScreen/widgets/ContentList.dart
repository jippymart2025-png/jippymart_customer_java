import 'package:flutter/material.dart';

import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/promotion_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

import '../../../core/responsive.dart';
import '../bannerdeals.dart';
import 'RestaurantSection.dart';
import 'appbar.dart';

/// Scrollable body once data has loaded: banner carousel, section
/// heading, and one [RestaurantSection] per vendor with active deals.
class ContentList extends StatelessWidget {
  const ContentList({
    super.key,
    required this.rs,
    required this.dealsBanners,
    required this.grouped,
    required this.productCache,
    required this.vendorCache,
    required this.restaurantStatusCache,
  });

  final Responsive rs;
  final List<BannerModel> dealsBanners;
  final Map<String, List<PromotionModel>> grouped;
  final Map<String, ProductModel> productCache;
  final Map<String, VendorModel> vendorCache;
  final Map<String, bool> restaurantStatusCache;

  String _restaurantName(String vendorId, List<PromotionModel> promos) {
    final title = vendorCache[vendorId]?.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final promoTitle = promos.first.restaurantTitle.trim();
    if (promoTitle.isNotEmpty) return promoTitle;
    return vendorId;
  }

  @override
  Widget build(BuildContext context) {
    final vendorIds = grouped.keys.toList()
      ..sort(
        (a, b) => _restaurantName(a, grouped[a]!).toLowerCase().compareTo(
          _restaurantName(b, grouped[b]!).toLowerCase(),
        ),
      );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        if (dealsBanners.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(rs.hPad, 14, rs.hPad, 0),
              child: DealsBannerView(banners: dealsBanners),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(rs.hPad, 20, rs.hPad, 10),
            child: Row(
              children: [
                const Text(
                  'Restaurants with deals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: C.text1,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                // TODO: wire up "See all" navigation once that
                // destination screen exists.
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: C.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: C.brand,
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((ctx, i) {
            final vid = vendorIds[i];
            final promos = grouped[vid]!;
            final vendor = vendorCache[vid];
            final isOpen = restaurantStatusCache[vid] ?? true;
            return RepaintBoundary(
              child: RestaurantSection(
                key: ValueKey(vid),
                vendorId: vid,
                vendor: vendor,
                promotions: promos,
                isOpen: isOpen,
                productCache: productCache,
                vendorCache: vendorCache,
                restaurantStatusCache: restaurantStatusCache,
                rs: rs,
              ),
            );
          }, childCount: vendorIds.length),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
