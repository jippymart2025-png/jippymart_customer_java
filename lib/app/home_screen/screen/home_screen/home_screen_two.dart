import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
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

const _kGradStart = Color(0xFFFF2D2D);
const _kGradEnd = Color(0xFFFF8C42);

/// How far the banner overlaps INTO the gradient (peeks above gradient bottom).
const double _kBannerPeekAbove = 80.0;

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreenTwo
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreenTwo extends StatelessWidget {
  const HomeScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, controller, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: _kGradStart,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemStatusBarContrastEnforced: false,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: RefreshIndicator(
              color: _kGradStart,
              onRefresh: () async => controller.getRefresh(context),
              child: _HomeBody(controller: controller),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeBody — decides which top-level view to show
// Extracted to avoid rebuilding the entire Scaffold on provider changes.
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final HomeProvider controller;

  const _HomeBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading || !controller.zoneCheckCompleted) {
      return const RestaurantLoadingWidget();
    }

    return Selector<BestRestaurantProvider, (bool, bool)>(
      selector: (_, p) => (p.isLoading, p.allNearestRestaurant.isEmpty),
      builder: (context, data, _) {
        final isLoading = data.$1;
        final isEmpty = data.$2;

        if (isLoading) return const RestaurantLoadingWidget();

        if (controller.hasActuallyCheckedZone &&
            Constant.isZoneAvailable == false &&
            isEmpty) {
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
// _NoServiceView
// Extracted from HomeScreenTwo for reusability and testability.
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/images/location.gif", height: 120),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppThemeData.grey800,
              fontSize: 22,
              fontFamily: AppThemeData.semiBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemeData.grey500,
              fontSize: 16,
              fontFamily: AppThemeData.bold,
            ),
          ),
          const SizedBox(height: 20),
          RoundedButtonFill(
            title: "Change Zone".tr,
            width: 55,
            height: 5.5,
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () => Get.offAll(() => const LocationPermissionScreen()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeMainContent
//
// CustomScrollView with two slivers:
//   1. _GradientHeroSliver — gradient hero (header + optional banner)
//   2. White content card  — categories, restaurants, ads, etc.
// ─────────────────────────────────────────────────────────────────────────────

class _HomeMainContent extends StatefulWidget {
  final HomeProvider controller;

  const _HomeMainContent({required this.controller});

  @override
  State<_HomeMainContent> createState() => _HomeMainContentState();
}

class _HomeMainContentState extends State<_HomeMainContent> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeroSliver(controller: widget.controller),
        ),
        SliverToBoxAdapter(
          child: _HomeContentCard(controller: widget.controller),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeContentCard
//
// The white rounded card below the gradient hero. Extracted to keep
// _HomeMainContentState lean and each section independently maintainable.
// ─────────────────────────────────────────────────────────────────────────────

class _HomeContentCard extends StatelessWidget {
  final HomeProvider controller;

  const _HomeContentCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasBanner = controller.bannerModel.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBanner) const SizedBox(height: _kBannerPeekAbove + 8),
          _CategorySection(),
          const SizedBox(height: 8),
          const BestRestaurantsSection(restaurantList: []),
          _AdvertisementSection(controller: controller),
          _BottomBannerSection(controller: controller),
          const SizedBox(height: 12),
          _AllRestaurantsSection(),
          const SizedBox(height: 25),
        ],
      ),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: CategoryView(),
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
// _AdvertisementCard — pure display; no provider reads inside list builder
// ─────────────────────────────────────────────────────────────────────────────

class _AdvertisementCard extends StatelessWidget {
  final List<AdvertisementModel> ads;
  final HomeProvider controller;

  /// Caps the visible ad count to avoid rendering off-screen items.
  static const int _maxVisibleAds = 6;

  const _AdvertisementCard({required this.ads, required this.controller});

  @override
  Widget build(BuildContext context) {
    final visibleAds = ads.length > _maxVisibleAds
        ? ads.sublist(0, _maxVisibleAds)
        : ads;

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppThemeData.primary300.withAlpha(40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Highlights for you".tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 16,
                        color: AppThemeData.grey900,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.to(
                        () => AllAdvertisementScreen(),
                      )?.then((_) => controller.getFavouriteRestaurant());
                    },
                    child: Text(
                      "See all".tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.regular,
                        color: AppThemeData.primary300,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
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
        ),
      ],
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
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
      child: BottomBannerView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AllRestaurantsSection
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                "All Restaurants",
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: FilterBar(
                selectedFilters: {},
                onFilterToggled: (f) => _handleFilterToggle(f, prov, context),
                availableFilters: data.$5,
                currentFilter: data.$4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                primary: false,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
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
          const SnackBar(
            content: Text('This filter is currently not available'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RestaurantCard
//
// Extracted from _HomeMainContentState so the GridView itemBuilder creates
// a true standalone widget — enabling widget-level rebuild isolation.
// ─────────────────────────────────────────────────────────────────────────────

class _RestaurantCard extends StatelessWidget {
  final VendorModel vendorModel;

  const _RestaurantCard({required this.vendorModel});

  @override
  Widget build(BuildContext context) {
    final rdp = context.read<RestaurantDetailsProvider>();
    final isClosed = !RestaurantStatusUtils.canAcceptOrders(vendorModel);

    return InkWell(
      onTap: isClosed
          ? null
          : () {
              rdp.initFunction(vendorModels: vendorModel);
              Get.to(() => const RestaurantDetailsScreen());
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeData.grey50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            // Using const BoxShadow avoids object allocation on each build.
            BoxShadow(
              color: Color(0x0D000000), // Colors.black @ 5%
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppThemeData.grey200.withOpacity(0.5),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RestaurantImageWithStatus(
                              vendorModel: vendorModel,
                              height: double.infinity,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: _StatusBadge(vendorModel: vendorModel),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendorModel.title ?? 'Restaurant',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppThemeData.semiBold,
                      color: AppThemeData.grey900,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 13,
                    child: _TimeThenFastDeliveryWidget(
                      deliveryTime: Constant.getDeliveryTimeText(vendorModel),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _BottomInfoRow(vendorModel: vendorModel),
                ],
              ),
            ),
            if (isClosed) const _ClosedOverlay(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClosedOverlay — const-constructible for maximum reuse
// ─────────────────────────────────────────────────────────────────────────────

class _ClosedOverlay extends StatelessWidget {
  const _ClosedOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'CLOSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: AppThemeData.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBadge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final VendorModel vendorModel;

  const _StatusBadge({required this.vendorModel});

  @override
  Widget build(BuildContext context) {
    final isOpen = RestaurantStatusUtils.canAcceptOrders(vendorModel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.9)
            : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.circle : Icons.circle_outlined,
            size: 6,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontFamily: AppThemeData.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomInfoRow
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
        Expanded(
          child: Row(
            children: [
              Icon(Icons.star, size: 12, color: AppThemeData.primary300),
              const SizedBox(width: 1),
              Expanded(
                child: Text(
                  _ratingText,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 10,
                color: AppThemeData.grey400,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  _distanceText,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey500,
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
// _GradientHeroSliver
//
// Paints the red→orange gradient as its own background using CustomPaint
// so it auto-sizes to exactly its content — header only or header + banner.
// ─────────────────────────────────────────────────────────────────────────────

class _GradientHeroSliver extends StatefulWidget {
  final HomeProvider controller;

  const _GradientHeroSliver({required this.controller});

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
    // Only measure when banners transition from absent → present.
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
    if (h > 0 && h != _bannerHeight) {
      setState(() => _bannerHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBanner = widget.controller.bannerModel.isNotEmpty;

    // Schedule measurement after layout only when a banner is present.
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: BannerView(key: bannerKey),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GradientPainter
//
// Renamed from _SvgHeroBackgroundPainter for clarity.
// Made const-constructible — one shared instance across all rebuilds.
// shouldRepaint returns false: gradient is static, no need to ever repaint.
// ─────────────────────────────────────────────────────────────────────────────

class _GradientPainter extends CustomPainter {
  const _GradientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_kGradStart, _kGradEnd],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Ratios derived from original SVG viewBox (400×220).
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _TimeThenFastDeliveryWidget
//
// Alternates between delivery time and "Fast delivery" text every 4 seconds.
// Timer is safely cancelled in dispose().
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
  static const _animDuration = Duration(milliseconds: 400);

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
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _showFastDelivery ? _fastDeliveryRow : _timeText,
      ),
    );
  }

  Widget get _fastDeliveryRow => Row(
    key: const ValueKey<String>('fast'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.delivery_dining, size: 10, color: AppThemeData.primary300),
      const SizedBox(width: 2),
      Expanded(
        child: Text(
          'Fast delivery',
          style: TextStyle(
            fontSize: 10,
            fontFamily: AppThemeData.medium,
            color: AppThemeData.primary300,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget get _timeText => Text(
    key: const ValueKey<String>('time'),
    widget.deliveryTime,
    style: TextStyle(
      fontSize: 10,
      fontFamily: AppThemeData.medium,
      color: AppThemeData.primary300,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AdvertisementHomeCard
//
// Caches VendorModel after the first Firestore fetch so subsequent taps
// on the same card don't trigger redundant network calls.
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
    return InkWell(
      onTap: () =>
          _onAdvertisementTap(context.read<RestaurantDetailsProvider>()),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: Responsive.width(70, context),
        decoration: BoxDecoration(
          color: AppThemeData.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 2,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdvImageSection(model: widget.model, cachedVendor: _cachedVendor),
            _AdvContentSection(
              model: widget.model,
              controller: widget.controller,
            ),
          ],
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
// _AdvImageSection — extracted from AdvertisementHomeCard._buildImageSection
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
                  top: Radius.circular(16),
                ),
                child: NetworkImageWidget(
                  imageUrl: model.coverImage ?? '',
                  height: 135,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : VideoAdvWidget(
                url: model.video ?? '',
                height: 135,
                width: double.infinity,
              ),
        if (_showRatingOverlay && cachedVendor != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: _RatingBadge(model: model, vendor: cachedVendor!),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RatingBadge
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
      decoration: ShapeDecoration(
        color: AppThemeData.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SvgPicture.asset(
              "assets/icons/ic_star.svg",
              colorFilter: ColorFilter.mode(
                AppThemeData.primary300,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$rating $review'.trim(),
              style: TextStyle(
                fontSize: 14,
                color: AppThemeData.primary300,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdvContentSection — extracted from AdvertisementHomeCard._buildContentSection
// ─────────────────────────────────────────────────────────────────────────────

class _AdvContentSection extends StatelessWidget {
  final AdvertisementModel model;
  final HomeProvider controller;

  const _AdvContentSection({required this.model, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (model.type == 'restaurant_promotion')
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: NetworkImageWidget(
                imageUrl: model.profileImage ?? '',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title ?? '',
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  model.description ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Container(
            decoration: ShapeDecoration(
              color: AppThemeData.primary50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(
                Icons.arrow_forward,
                size: 20,
                color: AppThemeData.primary300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
