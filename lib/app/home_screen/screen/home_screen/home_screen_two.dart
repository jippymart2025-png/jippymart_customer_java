import 'dart:math' show cos, sin;
import 'package:jippymart_customer/app/advertisement_screens/all_advertisement_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart'
    show BestRestaurantProvider;
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/banner_view_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/bottom_banner_view_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/best_restaurant_section_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/home_header_widget.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
import 'package:jippymart_customer/app/DealsScreen/DealsScreen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/widget/filter_bar.dart';
import 'package:jippymart_customer/widget/mini_cart_bar.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
import 'package:jippymart_customer/widget/video_widget.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/category_view_widget.dart';

class HomeScreenTwo extends StatelessWidget {
  const HomeScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, controller, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemStatusBarContrastEnforced: false,
          ),
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(ImageConst.backgroundImage),
                  fit: BoxFit.cover,
                ),
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.getRefresh(context);
                },
                child: _buildContent(controller, context),
              ),
            ),
            // floatingActionButton: _buildWhatsAppFAB(),
          ),
        );
      },
    );
  }

  Widget _buildContent(HomeProvider controller, BuildContext context) {
    if (controller.isLoading || !controller.zoneCheckCompleted) {
      return const RestaurantLoadingWidget();
    }

    return Selector<BestRestaurantProvider, (bool, bool)>(
      selector: (_, p) => (p.isLoading, p.allNearestRestaurant.isEmpty),
      builder: (context, data, _) {
        final isBestLoading = data.$1;
        final isAllNearestEmpty = data.$2;

        if (isBestLoading) {
          return const RestaurantLoadingWidget();
        }

        if (controller.hasActuallyCheckedZone &&
            Constant.isZoneAvailable == false &&
            isAllNearestEmpty) {
          return _buildNoServiceWidget(context);
        }

        return _buildMainContent(controller, context);
      },
    );
  }

  Widget _buildNoServiceWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/images/location.gif", height: 120),
          const SizedBox(height: 12),
          Text(
            Constant.isZoneAvailable == false
                ? "Service Not Available in Your Area".tr
                : "No Restaurants Found in Your Area".tr,
            style: TextStyle(
              color: AppThemeData.grey800,
              fontSize: 22,
              fontFamily: AppThemeData.semiBold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            Constant.isZoneAvailable == false
                ? "We don't currently deliver to your location. Please try a different address within our service area."
                      .tr
                : "Currently, there are no available restaurants in your zone. Try changing your location to find nearby options."
                      .tr,
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
            onPress: () {
              Get.offAll(() => const LocationPermissionScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(HomeProvider controller, BuildContext context) {
    return Column(
      children: [
        HomeHeaderWidget(
          key: ValueKey(Constant.selectedZone?.id ?? 'nozone'),
          homeProvider: controller,
          context: context,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildBannerSection(controller),
                _buildCategoryViewSection(controller),
                const SizedBox(height: 5),
                // _buildDealsBanner(context),
                const BestRestaurantsSection(restaurantList: []),
                _buildAdvertisementSection(controller, context),
                _buildBottomBannerSection(controller),
                const SizedBox(height: 10),
                _buildAllRestaurantsSection(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSection(HomeProvider controller) {
    return controller.bannerModel.isEmpty
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BannerView(),
          );
  }

  Widget _buildCategoryViewSection(HomeProvider controller) {
    return controller.bannerModel.isEmpty
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CategoryView(),
          );
  }

  Widget _buildAdvertisementSection(
    HomeProvider controller,
    BuildContext context,
  ) {
    final bestRestaurantProvider = context.read<BestRestaurantProvider>();

    if (Constant.isEnableAdsFeature != true) {
      return const SizedBox();
    }

    if (bestRestaurantProvider.isLoading &&
        bestRestaurantProvider.advertisementList.isEmpty) {
      return const RestaurantLoadingWidget();
    }

    if (bestRestaurantProvider.advertisementList.isEmpty) {
      return const SizedBox();
    }

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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Highlights for you".tr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 16,
                        color: AppThemeData.grey900,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.to(() => AllAdvertisementScreen())?.then((value) {
                        controller.getFavouriteRestaurant();
                      });
                    },
                    child: Text(
                      "See all".tr,
                      textAlign: TextAlign.center,
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
                  itemCount:
                      bestRestaurantProvider.advertisementList.length >= 6
                      ? 6
                      : bestRestaurantProvider.advertisementList.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (BuildContext context, int index) {
                    return RepaintBoundary(
                      child: AdvertisementHomeCard(
                        controller: controller,
                        model: bestRestaurantProvider.advertisementList[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBannerSection(HomeProvider controller) {
    return controller.bannerBottomModel.isEmpty
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            child: BottomBannerView(),
          );
  }

  Widget _buildDealsBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _navigateToDealsScreen(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.purple, AppThemeData.primary300.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppThemeData.primary300.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Add background and decorative elements here if needed
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/deals_banner.gif',
                    width: 60,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(width: 60);
                    },
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159),
                    child: Image.asset(
                      'assets/images/deals_banner.gif',
                      width: 60,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(width: 60);
                      },
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70),
                  child: Text(
                    "Grab The DEALS",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDealsScreen(BuildContext context) {
    final dashBoardProvider = Provider.of<DashBoardProvider>(
      context,
      listen: false,
    );
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final cartControllerProvider = Provider.of<CartControllerProvider>(
      context,
      listen: false,
    );
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final favouriteProvider = Provider.of<FavouriteProvider>(
      context,
      listen: false,
    );

    dashBoardProvider.changeNavbar(
      2,
      // Deals screen index
      homeProvider,
      splashProvider,
      cartControllerProvider,
      orderProvider,
      context,
      favouriteProvider,
    );
  }

  Widget _buildAllRestaurantsSection(BuildContext context) {
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
        final allRestaurants = data.$1;
        if (allRestaurants.isEmpty) {
          return const SizedBox.shrink();
        }
        final bestRestaurantProvider = context.read<BestRestaurantProvider>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: FilterBar(
                selectedFilters: {},
                onFilterToggled: (filter) => _handleFilterToggle(
                  filter,
                  bestRestaurantProvider,
                  context,
                ),
                availableFilters: data.$5,
                currentFilter: data.$4,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                primary: false,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allRestaurants.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return RepaintBoundary(
                    child: _buildRestaurantCard(allRestaurants[index], context),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleFilterToggle(
    FilterType filter,
    BestRestaurantProvider bestRestaurantProvider,
    BuildContext context,
  ) {
    String? apiFilter;
    switch (filter) {
      case FilterType.distance:
        apiFilter = 'distance';
        break;
      case FilterType.rating:
        apiFilter = 'rating';
        break;
      case FilterType.priceLowToHigh:
      case FilterType.priceHighToLow:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This filter is currently not available'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
    }
    bestRestaurantProvider.applyFilter(apiFilter);
  }

  Widget _buildRestaurantCard(VendorModel vendorModel, BuildContext context) {
    final restaurantDetailsProvider = context.read<RestaurantDetailsProvider>();
    final isClosed = !RestaurantStatusUtils.canAcceptOrders(vendorModel);

    return InkWell(
      onTap: isClosed
          ? null
          : () {
              restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
              Get.to(() => const RestaurantDetailsScreen());
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeData.grey50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                            child: _buildEnhancedStatusBadge(vendorModel),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 1),
                  _buildDeliveryTimeAndFastRow(vendorModel),
                  const SizedBox(height: 1),
                  // const Spacer(),
                  _buildBottomInfoRow(vendorModel),
                ],
              ),
            ),
            if (isClosed) _buildClosedOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedOverlay() {
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

  Widget _buildEnhancedStatusBadge(VendorModel vendorModel) {
    final isOpen = RestaurantStatusUtils.canAcceptOrders(vendorModel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.9)
            : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
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

  Widget _buildDeliveryTimeAndFastRow(VendorModel vendorModel) {
    final deliveryTime = Constant.getDeliveryTimeText(vendorModel);
    return SizedBox(
      height: 13,
      child: _TimeThenFastDeliveryWidget(deliveryTime: deliveryTime),
    );
  }

  Widget _buildBottomInfoRow(VendorModel vendorModel) {
    // Prefer backend/client-computed distance when available, fall back to live calculation
    String distanceText;
    if (vendorModel.distance != null && vendorModel.distance! > 0) {
      distanceText =
          '${vendorModel.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
    } else {
      distanceText =
          '${Constant.getDistanceFromVendor(vendorModel)} ${Constant.distanceType}';
    }
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.star, size: 12, color: AppThemeData.primary300),
              const SizedBox(width: 1),
              Expanded(
                child: Text(
                  "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())}",
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
                  distanceText,
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

  Widget _buildWhatsAppFAB() {
    return Consumer3<CartProvider, CartControllerProvider, HomeProvider>(
      builder:
          (context, cartProvider, cartControllerProvider, homeProvider, _) {
            final showMiniCart = HomeProvider.cartItem.isNotEmpty;
            return Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 0,
                  child: const MiniCartBar(),
                ),
                Positioned(
                  bottom: showMiniCart ? 100 : 16,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: _launchWhatsApp,
                    backgroundColor: Colors.green,
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: SvgPicture.asset(
                        'assets/images/whatsapp.svg',
                        width: 44,
                        height: 44,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }

  Future<void> _launchWhatsApp() async {
    const String phoneNumber = '+919390579864';
    const String message = 'Hello! I need help with my order.';
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        final Uri phoneUrl = Uri.parse('tel:$phoneNumber');
        if (await canLaunchUrl(phoneUrl)) {
          await launchUrl(phoneUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
    }
  }
}

/// First shows delivery time; after 2 seconds replaces it with "Fast delivery" in the same place (animated).
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

  @override
  void initState() {
    super.initState();
    // Loop: show time first, then "Fast delivery" after 2s, then time again, etc.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _showFastDelivery = !_showFastDelivery);
      }
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
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _showFastDelivery
            ? Row(
                key: const ValueKey<String>('fast'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 10,
                    color: AppThemeData.primary300,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Fast delivery',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.primary300,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Text(
                key: const ValueKey<String>('time'),
                widget.deliveryTime,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.primary300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildImageSection(), _buildContentSection()],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        widget.model.type == 'restaurant_promotion'
            ? ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: NetworkImageWidget(
                  imageUrl: widget.model.coverImage ?? '',
                  height: 135,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : VideoAdvWidget(
                url: widget.model.video ?? '',
                height: 135,
                width: double.infinity,
              ),
        if (widget.model.type != 'video_promotion' &&
            widget.model.vendorId != null &&
            (widget.model.showRating == true ||
                widget.model.showReview == true))
          Positioned(bottom: 8, right: 8, child: _buildRatingWidget()),
      ],
    );
  }

  Widget _buildRatingWidget() {
    if (_cachedVendor == null) {
      return const SizedBox();
    }

    final vendorModel = _cachedVendor!;
    return Container(
      decoration: ShapeDecoration(
        color: AppThemeData.primary50,
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
              "${widget.model.showRating == true ? Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString()) : ''} ${widget.model.showReview == true ? '(${vendorModel.reviewsCount!.toStringAsFixed(0)})' : ''}",
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

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.model.type == 'restaurant_promotion')
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: NetworkImageWidget(
                imageUrl: widget.model.profileImage ?? '',
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
                  widget.model.title ?? '',
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.model.description ?? '',
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

  Future<void> _onAdvertisementTap(
    RestaurantDetailsProvider restaurantDetailsProvider,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      VendorModel? vendorModel = _cachedVendor;
      if (vendorModel == null && widget.model.vendorId != null) {
        vendorModel = await FireStoreUtils.getVendorById(
          widget.model.vendorId!,
        );
        _cachedVendor = vendorModel;
      }
      ShowToastDialog.closeLoader();

      if (vendorModel != null) {
        restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
        Get.to(() => const RestaurantDetailsScreen());
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to load restaurant details".tr);
    }
  }
}
