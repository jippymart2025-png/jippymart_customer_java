import 'dart:math';

import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/advertisement_screens/all_advertisement_screen.dart';
import 'package:jippymart_customer/app/auth_screen/login_screen.dart';
import 'package:jippymart_customer/app/home_screen/provider/map_view_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/category_restaurant_screen/category_restaurant_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart'
    show BestRestaurantProvider;
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/best_restaurant_section_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/story_view_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/restaurant_list_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/story_view_screen/story_view.dart';
import 'package:jippymart_customer/app/home_screen/screen/view_all_category_screen/view_all_category_screen.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/mart_navigation_screen.dart';
import 'package:jippymart_customer/app/profile_screen/profile_screen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/swiggy_search_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/models/favourite_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/story_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/dark_theme_provider.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/restaurant_sorting_utils.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/widget/animated_search_hint.dart';
import 'package:jippymart_customer/widget/filter_bar.dart';
import 'package:jippymart_customer/widget/gradiant_text.dart';
import 'package:jippymart_customer/widget/initials_avatar.dart';
import 'package:jippymart_customer/widget/mini_cart_bar.dart';
import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
import 'package:jippymart_customer/widget/video_widget.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';
import 'package:jippymart_customer/widgets/coming_soon_dialog.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:latlong2/latlong.dart' as location;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../discount_restaurant_list_screen/discount_restaurant_list_screen.dart';
import 'widgets/category_view_widget.dart';

class HomeScreenTwo extends StatelessWidget {
  const HomeScreenTwo({super.key});

  static Future<void> _checkMartAvailability() async {
    try {
      if (Constant.selectedZone?.id == null) {
        ComingSoonDialogHelper.show(
          title: "COMING SOON".tr,
          message:
              "We're working hard to bring Jippy Mart to your area. Stay tuned!",
        );
        return;
      }
      final martVendors = await MartZoneUtils.getCachedMartVendors();
      if (martVendors.isEmpty) {
        ComingSoonDialogHelper.show(
          title: "COMING SOON".tr,
          message:
              "We're working hard to bring Jippy Mart to your area. Stay tuned!",
        );
        return;
      }
      final allClosed = martVendors.every((v) => v.isOpen == false);
      if (allClosed) {
        ComingSoonDialogHelper.show(
          title: "Mart Available from 7AM to 9PM".tr,
          message: "",
        );
        return;
      }
      Get.to(() => const MartNavigationScreen());
    } catch (e) {
      debugPrint("❌ Mart check failed: $e");
      ComingSoonDialogHelper.show(
        title: "COMING SOON".tr,
        message:
            "We're working hard to bring Jippy Mart to your area. Stay tuned!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(ImageConst.backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                controller.getRefresh(context);
              },
              child: controller.isLoading
                  ? const RestaurantLoadingWidget()
                  : Constant.isZoneAvailable == false
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/location.gif",
                            height: 120,
                          ),
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
                            onPress: () async {
                              Get.offAll(const LocationPermissionScreen());
                            },
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).viewPadding.top,
                      ),
                      child: controller.isListView == false
                          ? const MapView()
                          : Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                          top: 16,
                                          bottom: 16,
                                        ),
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                margin: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'FOOD',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  HomeScreenTwo._checkMartAvailability();
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      'MART',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Get.to(const ProfileScreen());
                                            },
                                            child: buildProfileAvatar(),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Constant.userModel == null
                                                    ? InkWell(
                                                        onTap: () {
                                                          Get.offAll(
                                                            const LoginScreen(),
                                                          );
                                                        },
                                                        child: Text(
                                                          "Login".tr,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppThemeData
                                                                    .medium,
                                                            color: AppThemeData
                                                                .grey900,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      )
                                                    : Text(
                                                        Constant.userModel!
                                                            .fullName(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              AppThemeData
                                                                  .medium,
                                                          color: AppThemeData
                                                              .grey900,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                InkWell(
                                                  onTap: () async {
                                                    if (Constant.userModel !=
                                                        null) {
                                                      Get.to(
                                                        const AddressListScreen(),
                                                      )!.then((value) {
                                                        if (value != null) {
                                                          ShippingAddress
                                                          addressModel = value;
                                                          Constant.selectedLocation =
                                                              addressModel;
                                                          controller.getData(
                                                            context,
                                                          );
                                                        }
                                                      });
                                                    } else {
                                                      Constant.checkPermission(
                                                        onTap: () async {
                                                          ShowToastDialog.showLoader(
                                                            "Please wait".tr,
                                                          );
                                                          ShippingAddress
                                                          addressModel =
                                                              ShippingAddress();
                                                          try {
                                                            await Geolocator.requestPermission();
                                                            await Geolocator.getCurrentPosition();
                                                            ShowToastDialog.closeLoader();
                                                            if (Constant
                                                                    .selectedMapType ==
                                                                'osm') {
                                                              final result =
                                                                  await Get.to(
                                                                    () =>
                                                                        MapPickerPage(),
                                                                  );
                                                              if (result !=
                                                                  null) {
                                                                final firstPlace =
                                                                    result;
                                                                final lat = firstPlace
                                                                    .coordinates
                                                                    .latitude;
                                                                final lng = firstPlace
                                                                    .coordinates
                                                                    .longitude;
                                                                final address =
                                                                    firstPlace
                                                                        .address;

                                                                addressModel
                                                                        .addressAs =
                                                                    "Home";
                                                                addressModel
                                                                    .locality = address
                                                                    .toString();
                                                                addressModel
                                                                        .location =
                                                                    UserLocation(
                                                                      latitude:
                                                                          lat,
                                                                      longitude:
                                                                          lng,
                                                                    );
                                                                Constant.selectedLocation =
                                                                    addressModel;
                                                                controller
                                                                    .getData(
                                                                      context,
                                                                    );
                                                                Get.back();
                                                              }
                                                            } else {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => PlacePicker(
                                                                    apiKey: Constant
                                                                        .mapAPIKey,
                                                                    onPlacePicked: (result) async {
                                                                      ShippingAddress
                                                                      addressModel =
                                                                          ShippingAddress();
                                                                      addressModel
                                                                              .addressAs =
                                                                          "Home";
                                                                      addressModel
                                                                          .locality = result
                                                                          .formattedAddress!
                                                                          .toString();
                                                                      addressModel
                                                                          .location = UserLocation(
                                                                        latitude: result
                                                                            .geometry!
                                                                            .location
                                                                            .lat,
                                                                        longitude: result
                                                                            .geometry!
                                                                            .location
                                                                            .lng,
                                                                      );
                                                                      Constant.selectedLocation =
                                                                          addressModel;
                                                                      controller
                                                                          .getData(
                                                                            context,
                                                                          );
                                                                      Get.back();
                                                                    },
                                                                    initialPosition:
                                                                        const LatLng(
                                                                          -33.8567844,
                                                                          151.213108,
                                                                        ),
                                                                    useCurrentLocation:
                                                                        true,
                                                                    selectInitialPosition:
                                                                        true,
                                                                    usePinPointingSearch:
                                                                        true,
                                                                    usePlaceDetailSearch:
                                                                        true,
                                                                    zoomGesturesEnabled:
                                                                        true,
                                                                    zoomControlsEnabled:
                                                                        true,
                                                                    resizeToAvoidBottomInset:
                                                                        false, // only works in page mode, less flickery, remove if wrong offsets
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            await placemarkFromCoordinates(
                                                              19.228825,
                                                              72.854118,
                                                            ).then((
                                                              valuePlaceMaker,
                                                            ) {
                                                              Placemark
                                                              placeMark =
                                                                  valuePlaceMaker[0];
                                                              addressModel
                                                                      .addressAs =
                                                                  "Home";
                                                              addressModel
                                                                      .location =
                                                                  UserLocation(
                                                                    latitude:
                                                                        19.228825,
                                                                    longitude:
                                                                        72.854118,
                                                                  );
                                                              String
                                                              currentLocation =
                                                                  "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                                                              addressModel
                                                                      .locality =
                                                                  currentLocation;
                                                            });

                                                            Constant.selectedLocation =
                                                                addressModel;
                                                            ShowToastDialog.closeLoader();
                                                            controller.getData(
                                                              context,
                                                            );
                                                          }
                                                        },
                                                        context: context,
                                                      );
                                                    }
                                                  },
                                                  child: Text.rich(
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: Constant
                                                              .selectedLocation
                                                              .getFullAddress(),
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppThemeData
                                                                    .medium,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            color: AppThemeData
                                                                .grey900,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        WidgetSpan(
                                                          child: SvgPicture.asset(
                                                            "assets/icons/ic_down.svg",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      InkWell(
                                        onTap: () {
                                          Get.to(
                                            () => const SwiggySearchScreen(),
                                          );
                                        },
                                        child: AnimatedSearchHint(
                                          controller: null,
                                          enable: false,
                                          fillColor: Colors.white,
                                          fontFamily: 'Outfit-Bold',
                                          textStyle: TextStyle(
                                            fontFamily: 'Outfit-Bold',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                          hintTextStyle: TextStyle(
                                            fontFamily: 'Outfit-Bold',
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: Colors.grey,
                                          ),
                                          suffix: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: SvgPicture.asset(
                                              "assets/icons/ic_search.svg",
                                              color: Color(0xFFff5201),
                                            ),
                                          ),
                                          hints: [
                                            // Food items
                                            "Search 'cake'",
                                            "Search 'biryani'",
                                            "Search 'ice cream'",
                                            "Search 'pizza'",
                                            "Search 'burger'",
                                            "Search 'sushi'",
                                            "Search 'restaurants'",
                                            "Search 'curry'",
                                            "Search 'noodles'",
                                            "Search 'tacos'",
                                            "Search 'chicken'",
                                            "Search 'salad'",
                                            "Search 'breakfast'",
                                            "Search 'pasta'",
                                            "Search 'soup'",
                                            "Search 'wraps'",
                                            "Search 'donuts'",
                                            "Search 'coffee'",
                                            "Search 'cookies'",
                                            "Search 'drinks'",

                                            // Motivational messages
                                            "Search 'healthy food'",
                                            "Search 'trending dishes'",
                                            "Search 'popular items'",
                                            "Search 'top rated'",
                                            "Search 'new arrivals'",
                                            "Search 'premium'",
                                            "Search 'best deals'",
                                            "Search 'award winning'",
                                            "Search 'special offers'",
                                            "Search 'today's special'",
                                            "Search 'gift ideas'",
                                            "Search 'late night'",
                                            "Search 'morning'",
                                            "Search 'evening'",
                                            "Search 'dinner'",
                                            "Search 'family meals'",
                                            "Search 'group orders'",
                                            "Search 'office lunch'",
                                            "Search 'party food'",
                                          ],
                                          interval: const Duration(seconds: 2),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                                Consumer<BestRestaurantProvider>(
                                  builder: (context, bestRestaurantProvider, _) {
                                    return Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            controller.bannerModel.isEmpty
                                                ? const SizedBox()
                                                : Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                        ),
                                                    child: BannerView(
                                                      controller: controller,
                                                    ),
                                                  ),
                                            const SizedBox(height: 20),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              child: CategoryView(),
                                            ),

                                            bestRestaurantProvider
                                                        .storyList
                                                        .isEmpty ||
                                                    (Constant.storyEnable ==
                                                            false &&
                                                        !kDebugMode)
                                                ? SizedBox()
                                                : Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 0,
                                                        ),
                                                    child: Column(
                                                      children: [
                                                        StoryView(
                                                          controller:
                                                              controller,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                            Visibility(
                                              visible:
                                                  Constant.isEnableAdsFeature ==
                                                  true,
                                              child:
                                                  bestRestaurantProvider
                                                      .advertisementList
                                                      .isEmpty
                                                  ? const SizedBox()
                                                  : Column(
                                                      children: [
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        Container(
                                                          margin:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                              ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 16,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                            color: AppThemeData
                                                                .primary300
                                                                .withAlpha(40),
                                                          ),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      "Highlights for you"
                                                                          .tr,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .start,
                                                                      style: TextStyle(
                                                                        fontFamily:
                                                                            AppThemeData.semiBold,
                                                                        fontSize:
                                                                            16,
                                                                        color: AppThemeData
                                                                            .grey900,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  InkWell(
                                                                    onTap: () {
                                                                      Get.to(
                                                                        AllAdvertisementScreen(),
                                                                      )?.then((
                                                                        value,
                                                                      ) {
                                                                        controller
                                                                            .getFavouriteRestaurant();
                                                                      });
                                                                    },
                                                                    child: Text(
                                                                      "See all"
                                                                          .tr,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style: TextStyle(
                                                                        fontFamily:
                                                                            AppThemeData.regular,
                                                                        color: AppThemeData
                                                                            .primary300,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                height: 16,
                                                              ),
                                                              SizedBox(
                                                                height: 220,
                                                                child: ListView.builder(
                                                                  physics:
                                                                      const BouncingScrollPhysics(),
                                                                  scrollDirection:
                                                                      Axis.horizontal,
                                                                  itemCount:
                                                                      bestRestaurantProvider
                                                                              .advertisementList
                                                                              .length >=
                                                                          10
                                                                      ? 10
                                                                      : bestRestaurantProvider
                                                                            .advertisementList
                                                                            .length,
                                                                  padding:
                                                                      EdgeInsets.all(
                                                                        0,
                                                                      ),
                                                                  itemBuilder:
                                                                      (
                                                                        BuildContext
                                                                        context,
                                                                        int
                                                                        index,
                                                                      ) {
                                                                        return AdvertisementHomeCard(
                                                                          controller:
                                                                              controller,
                                                                          model:
                                                                              bestRestaurantProvider.advertisementList[index],
                                                                        );
                                                                      },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                            BestRestaurantsSection(
                                              restaurantList:
                                                  bestRestaurantProvider
                                                      .allNearestRestaurant,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),
            ),
          ),
          floatingActionButton: Stack(
            children: [
              const Positioned(
                bottom: 0,
                left: 16,
                right: 0,
                child: MiniCartBar(),
              ),
              Positioned(
                bottom: cartItem.isNotEmpty ? 100 : 16,
                // Position above mini cart if active, otherwise at bottom
                right: 0,
                // Consistent right margin
                child: FloatingActionButton(
                  onPressed: () async {
                    const String phoneNumber =
                        '+919390579864'; // Your actual WhatsApp number
                    const String message =
                        'Hello! I need help with my order.'; // Customize the message
                    final Uri whatsappUrl = Uri.parse(
                      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
                    );
                    try {
                      if (await canLaunchUrl(whatsappUrl)) {
                        await launchUrl(
                          whatsappUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        final Uri phoneUrl = Uri.parse('tel:$phoneNumber');
                        if (await canLaunchUrl(phoneUrl)) {
                          await launchUrl(
                            phoneUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    } catch (e) {
                      print('Error launching WhatsApp: $e');
                    }
                  },
                  backgroundColor: Colors.green, // WhatsApp green color
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
          ),
        );
      },
    );
  }

  Widget buildProfileAvatar() {
    final user = Constant.userModel;
    final hasProfileImage =
        user != null &&
        user.profilePictureURL != null &&
        user.profilePictureURL!.isNotEmpty &&
        user.profilePictureURL!.toLowerCase() != "null";

    if (hasProfileImage) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppThemeData.primary300,
        backgroundImage: NetworkImage(user.profilePictureURL!),
      );
    } else {
      return InitialsAvatar(
        firstName: user?.firstName,
        lastName: user?.lastName,
        radius: 20,
        backgroundColor: AppThemeData.primary300,
        textColor: Colors.white,
      );
    }
  }
}

class BannerView extends StatelessWidget {
  final HomeProvider controller;

  const BannerView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: GestureDetector(
        onPanStart: (_) => controller.stopBannerTimer(),
        onPanEnd: (_) => controller.startBannerTimer(),
        child: PageView.builder(
          physics: const BouncingScrollPhysics(),
          controller: controller.pageController,
          scrollDirection: Axis.horizontal,
          itemCount: controller.bannerModel.length,
          padEnds: false,
          pageSnapping: true,
          onPageChanged: (value) {
            controller.currentPage.value = value;
          },
          itemBuilder: (BuildContext context, int index) {
            BannerModel bannerModel = controller.bannerModel[index];
            return InkWell(
              onTap: () async {
                controller.stopBannerTimer();
                if (bannerModel.redirectType == "store") {
                  ShowToastDialog.showLoader("Please wait".tr);
                  VendorModel? vendorModel = await FireStoreUtils.getVendorById(
                    bannerModel.redirectId.toString(),
                  );

                  if (vendorModel!.zoneId == Constant.selectedZone!.id) {
                    ShowToastDialog.closeLoader();
                    Get.to(
                      const RestaurantDetailsScreen(),
                      arguments: {"vendorModel": vendorModel},
                    );
                  } else {
                    ShowToastDialog.closeLoader();
                    ShowToastDialog.showToast(
                      "Sorry, The Zone is not available in your area. change the other location first."
                          .tr,
                    );
                  }
                } else if (bannerModel.redirectType == "product") {
                  ShowToastDialog.showLoader("Please wait".tr);
                  ProductModel? productModel =
                      await FireStoreUtils.getProductById(
                        bannerModel.redirectId.toString(),
                      );
                  VendorModel? vendorModel = await FireStoreUtils.getVendorById(
                    productModel!.vendorID.toString(),
                  );

                  if (vendorModel!.zoneId == Constant.selectedZone!.id) {
                    ShowToastDialog.closeLoader();
                    Get.to(
                      const RestaurantDetailsScreen(),
                      arguments: {"vendorModel": vendorModel},
                    );
                  } else {
                    ShowToastDialog.closeLoader();
                    ShowToastDialog.showToast(
                      "Sorry, The Zone is not available in your area. change the other location first."
                          .tr,
                    );
                  }
                } else if (bannerModel.redirectType == "external_link") {
                  final uri = Uri.parse(bannerModel.redirectId.toString());
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ShowToastDialog.showToast("Could not launch".tr);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: NetworkImageWidget(
                    imageUrl: bannerModel.photo.toString(),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AdvertisementHomeCard extends StatelessWidget {
  final AdvertisementModel model;
  final HomeProvider controller;

  const AdvertisementHomeCard({
    super.key,
    required this.controller,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        ShowToastDialog.showLoader("Please wait".tr);
        VendorModel? vendorModel = await FireStoreUtils.getVendorById(
          model.vendorId!,
        );
        ShowToastDialog.closeLoader();
        Get.to(
          const RestaurantDetailsScreen(),
          arguments: {"vendorModel": vendorModel},
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        width: Responsive.width(70, context),
        decoration: BoxDecoration(
          color: AppThemeData.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                model.type == 'restaurant_promotion'
                    ? ClipRRect(
                        borderRadius: BorderRadius.vertical(
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
                if (model.type != 'video_promotion' &&
                    model.vendorId != null &&
                    (model.showRating == true || model.showReview == true))
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FutureBuilder(
                      future: FireStoreUtils.getVendorById(model.vendorId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox();
                        } else {
                          if (snapshot.hasError) {
                            return const SizedBox();
                          } else if (snapshot.data == null) {
                            return const SizedBox();
                          } else {
                            VendorModel vendorModel = snapshot.data!;
                            return Container(
                              decoration: ShapeDecoration(
                                color: AppThemeData.primary50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(120),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
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
                                      "${model.showRating == true ? Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString()) : ''} ${model.showReview == true ? '(${vendorModel.reviewsCount!.toStringAsFixed(0)})' : ''}",
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
                      },
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
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
                  SizedBox(width: 8),
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
                  model.type == 'restaurant_promotion'
                      ? IconButton(
                          icon: Obx(
                            () =>
                                controller.favouriteList
                                    .where(
                                      (p0) => p0.restaurantId == model.vendorId,
                                    )
                                    .isNotEmpty
                                ? SvgPicture.asset(
                                    "assets/icons/ic_like_fill.svg",
                                  )
                                : SvgPicture.asset(
                                    "assets/icons/ic_like.svg",
                                    colorFilter: ColorFilter.mode(
                                      AppThemeData.grey600,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                          ),
                          onPressed: () async {
                            if (controller.favouriteList
                                .where(
                                  (p0) => p0.restaurantId == model.vendorId,
                                )
                                .isNotEmpty) {
                              FavouriteModel favouriteModel = FavouriteModel(
                                restaurantId: model.vendorId,
                                userId: FireStoreUtils.getCurrentUid(),
                              );
                              controller.favouriteList.removeWhere(
                                (item) => item.restaurantId == model.vendorId,
                              );
                              await FireStoreUtils.removeFavouriteRestaurant(
                                favouriteModel,
                              );
                            } else {
                              FavouriteModel favouriteModel = FavouriteModel(
                                restaurantId: model.vendorId,
                                userId: FireStoreUtils.getCurrentUid(),
                              );
                              controller.favouriteList.add(favouriteModel);
                              await FireStoreUtils.setFavouriteRestaurant(
                                favouriteModel,
                              );
                            }
                          },
                        )
                      : Container(
                          decoration: ShapeDecoration(
                            color: AppThemeData.primary50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: AppThemeData.primary300,
                            ),
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

class BannerBottomView extends StatelessWidget {
  final HomeProvider controller;

  const BannerBottomView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: controller.pageBottomController,
            scrollDirection: Axis.horizontal,
            itemCount: controller.bannerBottomModel.length,
            padEnds: false,
            pageSnapping: true,
            allowImplicitScrolling: true,
            onPageChanged: (value) {
              controller.currentBottomPage.value = value;
            },
            itemBuilder: (BuildContext context, int index) {
              BannerModel bannerModel = controller.bannerBottomModel[index];
              return InkWell(
                onTap: () async {
                  if (bannerModel.redirectType == "store") {
                    ShowToastDialog.showLoader("Please wait".tr);
                    VendorModel? vendorModel =
                        await FireStoreUtils.getVendorById(
                          bannerModel.redirectId.toString(),
                        );

                    if (vendorModel!.zoneId == Constant.selectedZone!.id) {
                      ShowToastDialog.closeLoader();
                      Get.to(
                        const RestaurantDetailsScreen(),
                        arguments: {"vendorModel": vendorModel},
                      );
                    } else {
                      ShowToastDialog.closeLoader();
                      ShowToastDialog.showToast(
                        "Sorry, The Zone is not available in your area. change the other location first."
                            .tr,
                      );
                    }
                  } else if (bannerModel.redirectType == "product") {
                    ShowToastDialog.showLoader("Please wait".tr);
                    ProductModel? productModel =
                        await FireStoreUtils.getProductById(
                          bannerModel.redirectId.toString(),
                        );
                    VendorModel? vendorModel =
                        await FireStoreUtils.getVendorById(
                          productModel!.vendorID.toString(),
                        );

                    if (vendorModel!.zoneId == Constant.selectedZone!.id) {
                      ShowToastDialog.closeLoader();
                      Get.to(
                        const RestaurantDetailsScreen(),
                        arguments: {"vendorModel": vendorModel},
                      );
                    } else {
                      ShowToastDialog.closeLoader();
                      ShowToastDialog.showToast(
                        "Sorry, The Zone is not available in your area. change the other location first."
                            .tr,
                      );
                    }
                  } else if (bannerModel.redirectType == "external_link") {
                    final uri = Uri.parse(bannerModel.redirectId.toString());
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ShowToastDialog.showToast("Could not launch".tr);
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: NetworkImageWidget(
                      imageUrl: bannerModel.photo.toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(controller.bannerBottomModel.length, (
              index,
            ) {
              return Obx(
                () => Container(
                  margin: const EdgeInsets.only(right: 5),
                  alignment: Alignment.centerLeft,
                  height: 9,
                  width: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.currentBottomPage.value == index
                        ? AppThemeData.primary300
                        : Colors.black12,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<MapViewProvider, BestRestaurantProvider, HomeProvider>(
      builder: (context, controller, bestRestaurantProvider, homeProvider, _) {
        return Stack(
          children: [
            Constant.selectedMapType == "osm"
                ? flutterMap.FlutterMap(
                    mapController: controller.osmMapController,
                    options: flutterMap.MapOptions(
                      initialCenter: location.LatLng(
                        Constant.selectedLocation.location!.latitude ?? 0.0,
                        Constant.selectedLocation.location!.longitude ?? 0.0,
                      ),
                      initialZoom: 10,
                    ),
                    children: [
                      flutterMap.TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      flutterMap.MarkerLayer(markers: controller.osmMarker),
                    ],
                  )
                : GoogleMap(
                    mapType: MapType.terrain,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    markers: Set<Marker>.of(controller.markers.values),
                    onMapCreated: (GoogleMapController mapController) {
                      controller.mapController = mapController;
                    },
                    mapToolbarEnabled: true,
                    initialCameraPosition: CameraPosition(
                      zoom: 18,
                      target:
                          bestRestaurantProvider.allNearestRestaurant.isEmpty
                          ? LatLng(
                              Constant.selectedLocation.location!.latitude ??
                                  45.521563,
                              Constant.selectedLocation.location!.longitude ??
                                  -122.677433,
                            )
                          : LatLng(
                              bestRestaurantProvider
                                      .allNearestRestaurant
                                      .first
                                      .latitude ??
                                  45.521563,
                              bestRestaurantProvider
                                      .allNearestRestaurant
                                      .first
                                      .longitude ??
                                  -122.677433,
                            ),
                    ),
                  ),
            bestRestaurantProvider.allNearestRestaurant.isEmpty
                ? Container()
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: SizedBox(
                        height: Responsive.height(25, context),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: PageView.builder(
                                pageSnapping: true,
                                controller: PageController(
                                  viewportFraction: 0.88,
                                ),
                                onPageChanged: (value) async {
                                  if (Constant.selectedMapType == "osm") {
                                    controller.osmMapController.move(
                                      location.LatLng(
                                        bestRestaurantProvider
                                            .allNearestRestaurant[value]
                                            .latitude!,
                                        bestRestaurantProvider
                                            .allNearestRestaurant[value]
                                            .longitude!,
                                      ),
                                      16,
                                    );
                                  } else {
                                    CameraUpdate cameraUpdate =
                                        CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                            zoom: 18,
                                            target: LatLng(
                                              bestRestaurantProvider
                                                  .allNearestRestaurant[value]
                                                  .latitude!,
                                              bestRestaurantProvider
                                                  .allNearestRestaurant[value]
                                                  .longitude!,
                                            ),
                                          ),
                                        );
                                    controller.mapController!.animateCamera(
                                      cameraUpdate,
                                    );
                                  }
                                },
                                itemCount: bestRestaurantProvider
                                    .allNearestRestaurant
                                    .length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  VendorModel vendorModel =
                                      bestRestaurantProvider
                                          .allNearestRestaurant[index];
                                  return InkWell(
                                    onTap: () {
                                      Get.to(
                                        const RestaurantDetailsScreen(),
                                        arguments: {"vendorModel": vendorModel},
                                      )?.then((v) {
                                        controller.homeController
                                            .getFavouriteRestaurant();
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: index == 0 ? 0 : 10,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppThemeData.grey50,
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(16),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(16),
                                                        topRight:
                                                            Radius.circular(16),
                                                      ),
                                                  child: Stack(
                                                    children: [
                                                      NetworkImageWidget(
                                                        imageUrl: vendorModel
                                                            .photo
                                                            .toString(),
                                                        fit: BoxFit.cover,
                                                        height:
                                                            Responsive.height(
                                                              14,
                                                              context,
                                                            ),
                                                        width: Responsive.width(
                                                          100,
                                                          context,
                                                        ),
                                                      ),
                                                      Container(
                                                        height:
                                                            Responsive.height(
                                                              14,
                                                              context,
                                                            ),
                                                        width: Responsive.width(
                                                          100,
                                                          context,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin:
                                                                const Alignment(
                                                                  -0.00,
                                                                  -1.00,
                                                                ),
                                                            end:
                                                                const Alignment(
                                                                  0,
                                                                  1,
                                                                ),
                                                            colors: [
                                                              Colors.black
                                                                  .withOpacity(
                                                                    0,
                                                                  ),
                                                              const Color(
                                                                0xFF111827,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        right: 10,
                                                        top: 10,
                                                        child: InkWell(
                                                          onTap: () async {
                                                            if (controller
                                                                .homeController
                                                                .favouriteList
                                                                .where(
                                                                  (p0) =>
                                                                      p0.restaurantId ==
                                                                      vendorModel
                                                                          .id,
                                                                )
                                                                .isNotEmpty) {
                                                              FavouriteModel
                                                              favouriteModel =
                                                                  FavouriteModel(
                                                                    restaurantId:
                                                                        vendorModel
                                                                            .id,
                                                                    userId:
                                                                        FireStoreUtils.getCurrentUid(),
                                                                  );
                                                              controller
                                                                  .homeController
                                                                  .favouriteList
                                                                  .removeWhere(
                                                                    (item) =>
                                                                        item.restaurantId ==
                                                                        vendorModel
                                                                            .id,
                                                                  );
                                                              await FireStoreUtils.removeFavouriteRestaurant(
                                                                favouriteModel,
                                                              );
                                                            } else {
                                                              FavouriteModel
                                                              favouriteModel =
                                                                  FavouriteModel(
                                                                    restaurantId:
                                                                        vendorModel
                                                                            .id,
                                                                    userId:
                                                                        FireStoreUtils.getCurrentUid(),
                                                                  );
                                                              controller
                                                                  .homeController
                                                                  .favouriteList
                                                                  .add(
                                                                    favouriteModel,
                                                                  );
                                                              await FireStoreUtils.setFavouriteRestaurant(
                                                                favouriteModel,
                                                              );
                                                            }
                                                          },
                                                          child: Obx(
                                                            () =>
                                                                controller
                                                                    .homeController
                                                                    .favouriteList
                                                                    .where(
                                                                      (p0) =>
                                                                          p0.restaurantId ==
                                                                          vendorModel
                                                                              .id,
                                                                    )
                                                                    .isNotEmpty
                                                                ? SvgPicture.asset(
                                                                    "assets/icons/ic_like_fill.svg",
                                                                  )
                                                                : SvgPicture.asset(
                                                                    "assets/icons/ic_like.svg",
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Transform.translate(
                                                  offset: Offset(
                                                    Responsive.width(
                                                      -3,
                                                      context,
                                                    ),
                                                    Responsive.height(
                                                      11,
                                                      context,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        decoration: ShapeDecoration(
                                                          color: AppThemeData
                                                              .primary50,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  120,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              SvgPicture.asset(
                                                                "assets/icons/ic_star.svg",
                                                                colorFilter:
                                                                    ColorFilter.mode(
                                                                      AppThemeData
                                                                          .primary300,
                                                                      BlendMode
                                                                          .srcIn,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Text(
                                                                "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                                                style: TextStyle(
                                                                  color: AppThemeData
                                                                      .primary300,
                                                                  fontFamily:
                                                                      AppThemeData
                                                                          .semiBold,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Container(
                                                        decoration: ShapeDecoration(
                                                          color: AppThemeData
                                                              .secondary50,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  120,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              SvgPicture.asset(
                                                                "assets/icons/ic_map_distance.svg",
                                                                colorFilter:
                                                                    const ColorFilter.mode(
                                                                      AppThemeData
                                                                          .secondary300,
                                                                      BlendMode
                                                                          .srcIn,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Text(
                                                                "${Constant.getDistance(lat1: vendorModel.latitude.toString(), lng1: vendorModel.longitude.toString(), lat2: Constant.selectedLocation.location!.latitude.toString(), lng2: Constant.selectedLocation.location!.longitude.toString())} ${Constant.distanceType}",
                                                                style: TextStyle(
                                                                  color: AppThemeData
                                                                      .secondary300,
                                                                  fontFamily:
                                                                      AppThemeData
                                                                          .semiBold,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    vendorModel.title
                                                        .toString(),
                                                    textAlign: TextAlign.start,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontFamily:
                                                          AppThemeData.semiBold,
                                                      color:
                                                          AppThemeData.grey900,
                                                    ),
                                                  ),
                                                  Text(
                                                    vendorModel.location
                                                        .toString(),
                                                    textAlign: TextAlign.start,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontFamily:
                                                          AppThemeData.medium,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppThemeData.grey400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
