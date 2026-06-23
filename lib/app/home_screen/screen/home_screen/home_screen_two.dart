// home_screen_two.dart — Premium redesign (Swiggy-inspired, JippyMart branded)
// All functionality preserved. Zero breaking changes to providers / models.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/group_order_section/create_group_order.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/order_type_View.dart';
import 'package:provider/provider.dart';

import 'package:jippymart_customer/app/advertisement_screens/all_advertisement_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart'
    show BestRestaurantProvider;
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/category_view_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/banner_view_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/best_restaurant_section_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/bottom_banner_view_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/home_header_widget.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/widget/filter_bar.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
import 'package:jippymart_customer/widget/video_widget.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';

import 'widgets/category_view_widget.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

// Primary gradient — warm food-app red→deep orange
const _kGradStart = Color(0xFFE8192C);
const _kGradEnd = Color(0xFFFF6B35);

// Accent & surface palette
const _kAccentAmber = Color(0xFFFFC107);
const _kSurfaceWhite = Color(0xFFFFFFFF);
const _kBgCanvas = Color(0xFFF7F7F8);
const _kCardShadow = Color(0x14000000);
const _kCardShadowMd = Color(0x1F000000);

// Status colours
const _kOpenGreen = Color(0xFF2ECC71);
const _kClosedRed = Color(0xFFE74C3C);

// Typography scale (used as named constants for clarity)
const _kFontXS = 9.0;
const _kFontSM = 11.0;
const _kFontMD = 13.0;
const _kFontLG = 15.0;
const _kFontXL = 18.0;
const _kFontXXL = 22.0;

// Radius tokens
const _kRadiusSM = 8.0;
const _kRadiusMD = 14.0;
const _kRadiusLG = 20.0;
const _kRadiusXL = 28.0;

/// How far the banner overlaps INTO the gradient.
const double _kBannerPeekAbove = 80.0;

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreenTwo
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreenTwo extends StatelessWidget {
  const HomeScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<HomeProvider>();
    final _ = context.select<HomeProvider, (bool, bool, int)>(
      (p) => (p.isLoading, p.zoneCheckCompleted, p.bannerModel.length),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _kBgCanvas,
        body: RefreshIndicator(
          color: _kGradStart,
          backgroundColor: _kSurfaceWhite,
          strokeWidth: 2.5,
          displacement: 60,
          onRefresh: () async => controller.getRefresh(context),
          child: _HomeBody(controller: controller),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeBody
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final HomeProvider controller;

  const _HomeBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading || !controller.zoneCheckCompleted) {
      return const RestaurantLoadingWidget();
    }

    return Selector<BestRestaurantProvider, int>(
      selector: (_, p) => p.allNearestRestaurant.length,
      builder: (context, outletCount, _) {
        if (controller.hasActuallyCheckedZone &&
            Constant.isZoneAvailable == false &&
            outletCount == 0) {
          return _NoServiceView(
            isZoneUnavailable: Constant.isZoneAvailable == false,
          );
        }

        return _HomeMainContent(controller: controller);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NoServiceView  — premium redesign
// ─────────────────────────────────────────────────────────────────────────────

class _NoServiceView extends StatelessWidget {
  final bool isZoneUnavailable;

  const _NoServiceView({required this.isZoneUnavailable});

  @override
  Widget build(BuildContext context) {
    final title = isZoneUnavailable
        ? "Service Not Available in Your Area".tr
        : "No Restaurants Found in Your Area".tr;

    final body = isZoneUnavailable
        ? "We don't currently deliver to your location. Please try a different address within our service area."
              .tr
        : "Currently, there are no available restaurants in your zone. Try changing your location to find nearby options."
              .tr;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF5F5), _kBgCanvas],
          stops: [0.0, 0.6],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Illustrated container
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kGradStart.withOpacity(0.12),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Image.asset("assets/images/location.gif", height: 90),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: _kFontXXL,
                fontFamily: AppThemeData.semiBold,
                height: 1.3,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppThemeData.grey500,
                fontSize: _kFontLG,
                fontFamily: AppThemeData.regular,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            // Premium CTA button
            _PremiumButton(
              label: "Change Location",
              icon: Icons.my_location_rounded,
              onTap: () => Get.offAll(() => const LocationPermissionScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable premium gradient button with icon + touch feedback
class _PremiumButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kGradStart, _kGradEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(50),
            // boxShadow: [
            //   BoxShadow(
            //     color: _kGradStart.withOpacity(0.35),
            //     blurRadius: 20,
            //     offset: const Offset(0, 8),
            //   ),
            // ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  label.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: _kFontLG,
                    fontFamily: AppThemeData.semiBold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeMainContent
// ─────────────────────────────────────────────────────────────────────────────

class _HomeMainContent extends StatefulWidget {
  final HomeProvider controller;

  const _HomeMainContent({required this.controller});

  @override
  State<_HomeMainContent> createState() => _HomeMainContentState();
}

class _HomeMainContentState extends State<_HomeMainContent> {
  final ScrollController _scroll = ScrollController();
  static const double _kStickySearchShowOffset = 120;
  static const double _kStickySearchHideOffset = 92;
  bool _showStickySearch = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scroll.hasClients) return;
    final offset = _scroll.offset;
    if (!_showStickySearch && offset >= _kStickySearchShowOffset && mounted) {
      setState(() => _showStickySearch = true);
      return;
    }
    if (_showStickySearch && offset <= _kStickySearchHideOffset && mounted) {
      setState(() => _showStickySearch = false);
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_handleScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).viewPadding.top;

    return Stack(
      children: [
        CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _GradientHeroSliver(
                controller: widget.controller,
                showInlineSearch: !_showStickySearch,
              ),
            ),
            SliverToBoxAdapter(
              child: _HomeContentCard(controller: widget.controller),
            ),
            const _AllRestaurantsHeaderSliver(),
            const _AllRestaurantsGridSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !_showStickySearch,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              opacity: _showStickySearch ? 1 : 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                offset: _showStickySearch
                    ? Offset.zero
                    : const Offset(0, -0.15),
                child: Container(
                  color: _kBgCanvas,
                  padding: EdgeInsets.fromLTRB(16, topPadding, 16, 6),
                  child: const RepaintBoundary(child: HomeSearchBar()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeContentCard  — white rounded card below the hero
// ─────────────────────────────────────────────────────────────────────────────

class _HomeContentCard extends StatelessWidget {
  final HomeProvider controller;

  const _HomeContentCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasBanner = controller.bannerModel.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: _kBgCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_kRadiusXL)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBanner) const SizedBox(height: _kBannerPeekAbove + 12),
          // const SizedBox(height: 0),
          _ordertypeSection(),
          _CategorySection(),
          const SizedBox(height: 8),
          const BestRestaurantsSection(restaurantList: []),
          _AdvertisementSection(controller: controller),
          _BottomBannerSection(controller: controller),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

//new impliment of orders

class _ordertypeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CategoryViewProvider>();
    if (prov.vendorCategoryModel.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 12)),
        OrderOptionsView(
          onGroupOrderingTap: () {
            Get.to(() => const CreateGroupOrderScreen());
          },
          onHomeMadeMealsTap: () {
            // TODO: navigate to Home Made Meals screen
          },
          onDineInTap: () {
            // TODO: navigate to Dine In screen
          },
          onMultiOrderingTap: () {
            // TODO: navigate to Multi Ordering screen
          },
          onScheduleOrderTap: () {
            // TODO: navigate to Schedule Order screen
          },
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// _CategorySection
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CategoryViewProvider>();
    if (prov.vendorCategoryModel.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: CategoryView(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdvertisementSection
// ─────────────────────────────────────────────────────────────────────────────

class _AdvertisementSection extends StatelessWidget {
  final HomeProvider controller;

  const _AdvertisementSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (Constant.isEnableAdsFeature != true) return const SizedBox.shrink();

    return Selector<BestRestaurantProvider, (bool, List<AdvertisementModel>)>(
      selector: (_, p) => (p.isLoading, p.advertisementList),
      builder: (context, data, _) {
        final isLoading = data.$1;
        final ads = data.$2;

        if (isLoading && ads.isEmpty) return const RestaurantLoadingWidget();
        if (ads.isEmpty) return const SizedBox.shrink();

        return _AdvertisementCard(ads: ads, controller: controller);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdvertisementCard  — premium redesign
// ─────────────────────────────────────────────────────────────────────────────

class _AdvertisementCard extends StatelessWidget {
  final List<AdvertisementModel> ads;
  final HomeProvider controller;

  static const int _maxVisibleAds = 6;

  const _AdvertisementCard({required this.ads, required this.controller});

  @override
  Widget build(BuildContext context) {
    final visibleAds = ads.length > _maxVisibleAds
        ? ads.sublist(0, _maxVisibleAds)
        : ads;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kGradStart, _kGradEnd],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Highlights for you".tr,
                    style: const TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: _kFontXL,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(
                      () => AllAdvertisementScreen(),
                    )?.then((_) => controller.getFavouriteRestaurant());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _kGradStart.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "See all".tr,
                      style: const TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        color: _kGradStart,
                        fontSize: _kFontMD,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal carousel
          SizedBox(
            height: 230,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 4),
              itemCount: visibleAds.length,
              itemBuilder: (ctx, i) => RepaintBoundary(
                child: AdvertisementHomeCard(
                  controller: controller,
                  model: visibleAds[i],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomBannerSection
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBannerSection extends StatelessWidget {
  final HomeProvider controller;

  const _BottomBannerSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.bannerBottomModel.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: BottomBannerView(),
    );
  }
}

class _AllRestaurantsHeaderSliver extends StatelessWidget {
  const _AllRestaurantsHeaderSliver();

  @override
  Widget build(BuildContext context) {
    return Selector<BestRestaurantProvider, int>(
      selector: (_, p) => p.allNearestRestaurant.length,
      builder: (context, count, _) {
        if (count == 0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kGradStart, _kGradEnd],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "All Restaurants".tr,
                      style: const TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        color: Color(0xFF1A1A2E),
                        fontSize: _kFontXL,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _kGradStart.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: _kFontSM,
                          fontFamily: AppThemeData.semiBold,
                          color: _kGradStart,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              //   child: FilterBar(
              //     selectedFilters: {},
              //     onFilterToggled: (f) => _handleFilterToggle(f, prov, context),
              //     availableFilters: data.$4,
              //     currentFilter: data.$3,
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Divider(
                  color: AppThemeData.grey200,
                  thickness: 1,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleFilterToggle(
    FilterType filter,
    BestRestaurantProvider prov,
    BuildContext context,
  ) {
    switch (filter) {
      case FilterType.distance:
        prov.applyFilter('distance');
        break;
      case FilterType.rating:
        prov.applyFilter('rating');
        break;
      case FilterType.priceLowToHigh:
      case FilterType.priceHighToLow:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This filter is currently not available'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }
}

class _AllRestaurantsGridSliver extends StatelessWidget {
  const _AllRestaurantsGridSliver();

  @override
  Widget build(BuildContext context) {
    return Selector<BestRestaurantProvider, int>(
      selector: (_, p) => p.allNearestRestaurant.length,
      builder: (context, count, _) {
        final all = context.read<BestRestaurantProvider>().allNearestRestaurant;
        if (count == 0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          sliver: SliverPadding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate((ctx, i) {
                return RepaintBoundary(
                  child: _RestaurantCard(vendorModel: all[i]),
                );
              }, childCount: count),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AllRestaurantsSection  — premium grid redesign
// ─────────────────────────────────────────────────────────────────────────────

class _AllRestaurantsSection extends StatelessWidget {
  const _AllRestaurantsSection();

  @override
  Widget build(BuildContext context) {
    return Selector<
      BestRestaurantProvider,
      (List<VendorModel>, int, bool, String?, List<String>)
    >(
      selector: (_, p) => (
        p.allNearestRestaurant,
        p.allNearestRestaurant.length,
        p.isLoading,
        p.currentFilter,
        p.availableFilters,
      ),
      shouldRebuild: (prev, next) =>
          prev.$2 != next.$2 ||
          prev.$3 != next.$3 ||
          prev.$4 != next.$4 ||
          prev.$5 != next.$5,
      builder: (context, data, _) {
        final all = data.$1;
        if (all.isEmpty) return const SizedBox.shrink();

        final prov = context.read<BestRestaurantProvider>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kGradStart, _kGradEnd],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "All Restaurants".tr,
                    style: const TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      color: Color(0xFF1A1A2E),
                      fontSize: _kFontXL,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kGradStart.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${all.length}',
                      style: const TextStyle(
                        fontSize: _kFontSM,
                        fontFamily: AppThemeData.semiBold,
                        color: _kGradStart,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: FilterBar(
                selectedFilters: {},
                onFilterToggled: (f) => _handleFilterToggle(f, prov, context),
                availableFilters: data.$5,
                currentFilter: data.$4,
              ),
            ),

            // Thin divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(
                color: AppThemeData.grey200,
                thickness: 1,
                height: 1,
              ),
            ),

            // Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.builder(
                shrinkWrap: true,
                primary: false,
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (ctx, i) => RepaintBoundary(
                  child: _RestaurantCard(vendorModel: all[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleFilterToggle(
    FilterType filter,
    BestRestaurantProvider prov,
    BuildContext context,
  ) {
    switch (filter) {
      case FilterType.distance:
        prov.applyFilter('distance');
        break;
      case FilterType.rating:
        prov.applyFilter('rating');
        break;
      case FilterType.priceLowToHigh:
      case FilterType.priceHighToLow:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This filter is currently not available'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RestaurantCard  — premium redesign with better image, spacing & hierarchy
// ─────────────────────────────────────────────────────────────────────────────

class _RestaurantCard extends StatelessWidget {
  final VendorModel vendorModel;

  const _RestaurantCard({required this.vendorModel});

  @override
  Widget build(BuildContext context) {
    final rdp = context.read<RestaurantDetailsProvider>();
    final isClosed = !RestaurantStatusUtils.canAcceptOrders(vendorModel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isClosed
            ? null
            : () {
                rdp.initFunction(vendorModels: vendorModel);
                Get.to(() => const RestaurantDetailsScreen());
              },
        borderRadius: BorderRadius.circular(_kRadiusMD),
        child: Ink(
          decoration: BoxDecoration(
            color: _kSurfaceWhite,
            borderRadius: BorderRadius.circular(_kRadiusMD),
            boxShadow: const [
              BoxShadow(
                color: _kCardShadow,
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image container with aspect ratio
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_kRadiusSM + 2),
                          color: const Color(0xFFF0F0F0),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                _kRadiusSM + 2,
                              ),
                              child: RestaurantImageWithStatus(
                                vendorModel: vendorModel,
                                height: double.infinity,
                                width: double.infinity,
                              ),
                            ),
                            // Status badge top-left
                            Positioned(
                              top: 5,
                              left: 5,
                              child: _StatusBadge(vendorModel: vendorModel),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    // Restaurant name
                    Text(
                      vendorModel.title ?? 'Restaurant',
                      style: const TextStyle(
                        fontSize: _kFontMD,
                        fontFamily: AppThemeData.semiBold,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    // Delivery time / fast delivery toggle
                    SizedBox(
                      height: 14,
                      child: _TimeThenFastDeliveryWidget(
                        deliveryTime: Constant.getDeliveryTimeText(vendorModel),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Rating + distance row
                    _BottomInfoRow(vendorModel: vendorModel),
                  ],
                ),
              ),

              // Closed overlay
              if (isClosed) const _ClosedOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClosedOverlay  — refined frosted-glass look
// ─────────────────────────────────────────────────────────────────────────────

class _ClosedOverlay extends StatelessWidget {
  const _ClosedOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.38),
          borderRadius: BorderRadius.circular(_kRadiusMD),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'CLOSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: _kFontXS + 1,
                fontFamily: AppThemeData.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBadge  — sharper pill badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final VendorModel vendorModel;

  const _StatusBadge({required this.vendorModel});

  @override
  Widget build(BuildContext context) {
    final isOpen = RestaurantStatusUtils.canAcceptOrders(vendorModel);
    final bgColor = isOpen
        ? _kOpenGreen.withOpacity(0.92)
        : _kClosedRed.withOpacity(0.92);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: _kFontXS,
              fontFamily: AppThemeData.bold,
              height: 1,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomInfoRow  — refined with consistent icon sizing
// ─────────────────────────────────────────────────────────────────────────────

class _BottomInfoRow extends StatelessWidget {
  final VendorModel vendorModel;

  const _BottomInfoRow({required this.vendorModel});

  String get _distanceText {
    if (vendorModel.distance != null && vendorModel.distance! > 0) {
      return '${vendorModel.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
    }
    return '${Constant.getDistanceFromVendor(vendorModel)} ${Constant.distanceType}';
  }

  String get _ratingText => Constant.calculateReview(
    reviewCount: vendorModel.reviewsCount.toString(),
    reviewSum: vendorModel.reviewsSum.toString(),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Rating
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.star_rounded, size: 11, color: _kAccentAmber),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  _ratingText,
                  style: const TextStyle(
                    fontSize: _kFontXS + 1,
                    fontFamily: AppThemeData.semiBold,
                    color: Color(0xFF555570),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Dot separator
        Container(
          width: 3,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Color(0xFFCCCCCC),
            shape: BoxShape.circle,
          ),
        ),

        // Distance
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.near_me_rounded,
                size: 10,
                color: AppThemeData.grey400,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  _distanceText,
                  style: const TextStyle(
                    fontSize: _kFontXS,
                    fontFamily: AppThemeData.medium,
                    color: Color(0xFF888899),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GradientHeroSliver  — seamless status-bar integration
// ─────────────────────────────────────────────────────────────────────────────

class _GradientHeroSliver extends StatefulWidget {
  final HomeProvider controller;
  final bool showInlineSearch;

  const _GradientHeroSliver({
    required this.controller,
    required this.showInlineSearch,
  });

  @override
  State<_GradientHeroSliver> createState() => _GradientHeroSliverState();
}

class _GradientHeroSliverState extends State<_GradientHeroSliver> {
  double _bannerHeight = 160.0;
  final GlobalKey _bannerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.controller.bannerModel.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureBanner());
    }
  }

  @override
  void didUpdateWidget(covariant _GradientHeroSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.bannerModel.isEmpty &&
        widget.controller.bannerModel.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureBanner());
    }
  }

  void _measureBanner() {
    final ctx = _bannerKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final h = box.size.height;
    if (h > 0 && h != _bannerHeight) setState(() => _bannerHeight = h);
  }

  @override
  Widget build(BuildContext context) {
    final hasBanner = widget.controller.bannerModel.isNotEmpty;
    if (hasBanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureBanner());
    }

    return CustomPaint(
      painter: const _GradientPainter(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeHeaderWidget(
            key: ValueKey(Constant.selectedZone?.id ?? 'nozone'),
            homeProvider: widget.controller,
            context: context,
            showSearchBar: widget.showInlineSearch,
          ),
          if (hasBanner)
            _OverlapBannerRow(
              bannerKey: _bannerKey,
              bannerHeight: _bannerHeight,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OverlapBannerRow
// ─────────────────────────────────────────────────────────────────────────────

class _OverlapBannerRow extends StatelessWidget {
  final GlobalKey bannerKey;
  final double bannerHeight;

  const _OverlapBannerRow({
    required this.bannerKey,
    required this.bannerHeight,
  });

  @override
  Widget build(BuildContext context) {
    final belowHeight = (bannerHeight - _kBannerPeekAbove).clamp(
      0.0,
      double.infinity,
    );

    return SizedBox(
      width: double.infinity,
      height: belowHeight,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: bannerHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BannerView(key: bannerKey),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GradientPainter  — deeper, richer gradient with subtle mesh feel
// ─────────────────────────────────────────────────────────────────────────────

class _GradientPainter extends CustomPainter {
  const _GradientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Main gradient fill
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_kGradStart, Color(0xFFFF4E1F), _kGradEnd],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final cornerStartY = size.height * (180.0 / 220.0);
    final cornerInsetX = size.width * (40.0 / 400.0);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cornerStartY)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - cornerInsetX,
        size.height,
      )
      ..lineTo(cornerInsetX, size.height)
      ..quadraticBezierTo(0, size.height, 0, cornerStartY)
      ..close();

    canvas.drawPath(path, paint);

    // Subtle warm highlight overlay (top-right)
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.6),
        radius: 0.7,
        colors: [Colors.white.withOpacity(0.12), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _TimeThenFastDeliveryWidget  — refined with better icon & colours
// ─────────────────────────────────────────────────────────────────────────────

class _TimeThenFastDeliveryWidget extends StatefulWidget {
  final String deliveryTime;

  const _TimeThenFastDeliveryWidget({required this.deliveryTime});

  @override
  State<_TimeThenFastDeliveryWidget> createState() =>
      _TimeThenFastDeliveryWidgetState();
}

class _TimeThenFastDeliveryWidgetState
    extends State<_TimeThenFastDeliveryWidget> {
  bool _showFastDelivery = false;
  Timer? _timer;

  static const _switchDuration = Duration(seconds: 4);
  static const _animDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_switchDuration, (_) {
      if (mounted) setState(() => _showFastDelivery = !_showFastDelivery);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: _animDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _showFastDelivery ? _fastDeliveryRow : _timeText,
      ),
    );
  }

  Widget get _fastDeliveryRow => Row(
    key: const ValueKey<String>('fast'),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.electric_bolt_rounded, size: 10, color: _kGradStart),
      const SizedBox(width: 2),
      Expanded(
        child: Text(
          'Fast delivery',
          style: const TextStyle(
            fontSize: _kFontXS + 1,
            fontFamily: AppThemeData.semiBold,
            color: _kGradStart,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget get _timeText => Row(
    key: const ValueKey<String>('time'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.access_time_rounded, size: 10, color: AppThemeData.grey500),
      const SizedBox(width: 2),
      Expanded(
        child: Text(
          widget.deliveryTime,
          style: TextStyle(
            fontSize: _kFontXS + 1,
            fontFamily: AppThemeData.medium,
            color: AppThemeData.grey500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AdvertisementHomeCard  — premium card with refined layout
// ─────────────────────────────────────────────────────────────────────────────

class AdvertisementHomeCard extends StatefulWidget {
  final AdvertisementModel model;
  final HomeProvider controller;

  const AdvertisementHomeCard({
    super.key,
    required this.controller,
    required this.model,
  });

  @override
  State<AdvertisementHomeCard> createState() => _AdvertisementHomeCardState();
}

class _AdvertisementHomeCardState extends State<AdvertisementHomeCard> {
  VendorModel? _cachedVendor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _onAdvertisementTap(context.read<RestaurantDetailsProvider>()),
          borderRadius: BorderRadius.circular(_kRadiusLG),
          child: Ink(
            width: Responsive.width(68, context),
            decoration: BoxDecoration(
              color: _kSurfaceWhite,
              borderRadius: BorderRadius.circular(_kRadiusLG),
              boxShadow: const [
                BoxShadow(
                  color: _kCardShadowMd,
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdvImageSection(
                  model: widget.model,
                  cachedVendor: _cachedVendor,
                ),
                _AdvContentSection(
                  model: widget.model,
                  controller: widget.controller,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAdvertisementTap(RestaurantDetailsProvider rdp) async {
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      VendorModel? v = _cachedVendor;
      if (v == null && widget.model.vendorId != null) {
        v = await FireStoreUtils.getVendorById(widget.model.vendorId!);
        if (mounted) _cachedVendor = v;
      }
      ShowToastDialog.closeLoader();
      if (v != null) {
        rdp.initFunction(vendorModels: v);
        Get.to(() => const RestaurantDetailsScreen());
      }
    } catch (_) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to load restaurant details".tr);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdvImageSection
// ─────────────────────────────────────────────────────────────────────────────

class _AdvImageSection extends StatelessWidget {
  final AdvertisementModel model;
  final VendorModel? cachedVendor;

  const _AdvImageSection({required this.model, required this.cachedVendor});

  bool get _showRatingOverlay =>
      model.type != 'video_promotion' &&
      model.vendorId != null &&
      (model.showRating == true || model.showReview == true);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        model.type == 'restaurant_promotion'
            ? ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_kRadiusLG),
                ),
                child: NetworkImageWidget(
                  imageUrl: model.coverImage ?? '',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_kRadiusLG),
                ),
                child: VideoAdvWidget(
                  url: model.video ?? '',
                  height: 140,
                  width: double.infinity,
                ),
              ),
        // Gradient overlay for readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
          ),
        ),
        if (_showRatingOverlay && cachedVendor != null)
          Positioned(
            bottom: 10,
            right: 10,
            child: _RatingBadge(model: model, vendor: cachedVendor!),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RatingBadge  — compact pill with amber star
// ─────────────────────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final AdvertisementModel model;
  final VendorModel vendor;

  const _RatingBadge({required this.model, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final rating = model.showRating == true
        ? Constant.calculateReview(
            reviewCount: vendor.reviewsCount!.toStringAsFixed(0),
            reviewSum: vendor.reviewsSum.toString(),
          )
        : '';
    final review = model.showReview == true
        ? '(${vendor.reviewsCount!.toStringAsFixed(0)})'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: _kAccentAmber),
          const SizedBox(width: 4),
          Text(
            '$rating $review'.trim(),
            style: const TextStyle(
              fontSize: _kFontMD,
              color: Color(0xFF1A1A2E),
              fontFamily: AppThemeData.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdvContentSection  — tighter, more premium layout
// ─────────────────────────────────────────────────────────────────────────────

class _AdvContentSection extends StatelessWidget {
  final AdvertisementModel model;
  final HomeProvider controller;

  const _AdvContentSection({required this.model, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (model.type == 'restaurant_promotion')
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: NetworkImageWidget(
                  imageUrl: model.profileImage ?? '',
                  height: 42,
                  width: 42,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  model.title ?? '',
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: _kFontMD,
                    fontFamily: AppThemeData.semiBold,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  model.description ?? '',
                  style: const TextStyle(
                    fontSize: _kFontXS + 1,
                    fontFamily: AppThemeData.regular,
                    color: Color(0xFF888899),
                    height: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Arrow CTA
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGradStart, _kGradEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(_kRadiusSM),
              boxShadow: [
                BoxShadow(
                  color: _kGradStart.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// home_screen_two.dart — Premium redesign (Swiggy-inspired, JippyMart branded)
// All functionality preserved. Zero breaking changes to providers / models.
// Change: Added sticky search bar sliver between hero and conten
