import 'package:jippymart_customer/app/advertisement_screens/all_advertisement_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart'
    show BestRestaurantProvider;
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/banner_view_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/best_restaurant_section_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/home_profile_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/home_screen_search_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/mart_food_tab_bar_widget.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/story_view_widget.dart';
import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
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
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/widget/mini_cart_bar.dart';
import 'package:jippymart_customer/widget/video_widget.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/category_view_widget.dart';

class HomeScreenTwo extends StatelessWidget {
  const HomeScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      HomeProvider,
      MartProvider,
      MartNavigationProvider,
      BestRestaurantProvider
    >(
      builder:
          (
            context,
            controller,
            martProvider,
            martNavigationProvider,
            bestRestaurantProvider,
            _,
          ) {
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
                  child:
                      controller.isLoading &&
                          bestRestaurantProvider.allNearestRestaurant.isEmpty
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
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    martFoodTabBarWidgetHome(
                                      martProvider: martProvider,
                                      martNavigationProvider:
                                          martNavigationProvider,
                                      context: context,
                                    ),
                                    homeProfileAddressWidget(
                                      homeProvider: controller,
                                      context: context,
                                    ),
                                    const SizedBox(height: 20),
                                    homeScreenSearchWidget(),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                              Expanded(
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
                                              child: BannerView(),
                                            ),
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: CategoryView(),
                                      ),
                                      bestRestaurantProvider
                                                  .storyList
                                                  .isEmpty ||
                                              (Constant.storyEnable == false &&
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
                                                    controller: controller,
                                                  ),
                                                ],
                                              ),
                                            ),
                                      Visibility(
                                        visible:
                                            Constant.isEnableAdsFeature == true,
                                        child:
                                            bestRestaurantProvider
                                                .advertisementList
                                                .isEmpty
                                            ? const SizedBox()
                                            : Column(
                                                children: [
                                                  const SizedBox(height: 20),
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
                                                                      AppThemeData
                                                                          .semiBold,
                                                                  fontSize: 16,
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
                                                                "See all".tr,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      AppThemeData
                                                                          .regular,
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
                                                                  int index,
                                                                ) {
                                                                  return AdvertisementHomeCard(
                                                                    controller:
                                                                        controller,
                                                                    model: bestRestaurantProvider
                                                                        .advertisementList[index],
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
                                        restaurantList: bestRestaurantProvider
                                            .allNearestRestaurant,
                                      ),
                                    ],
                                  ),
                                ),
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
    return Consumer<RestaurantDetailsProvider>(
      builder: (context, restaurantDetailsProvider, _) {
        return InkWell(
          onTap: () async {
            ShowToastDialog.showLoader("Please wait".tr);
            VendorModel? vendorModel = await FireStoreUtils.getVendorById(
              model.vendorId!,
            );
            ShowToastDialog.closeLoader();
            restaurantDetailsProvider.initFunction(
              vendorModels: vendorModel ?? VendorModel(),
            );
            Get.to(const RestaurantDetailsScreen());
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
                      // model.type == 'restaurant_promotion'
                      //     ? IconButton(
                      //         icon: Obx(
                      //           () =>
                      //               controller.favouriteList
                      //                   .where(
                      //                     (p0) => p0.restaurantId == model.vendorId,
                      //                   )
                      //                   .isNotEmpty
                      //               ? SvgPicture.asset(
                      //                   "assets/icons/ic_like_fill.svg",
                      //                 )
                      //               : SvgPicture.asset(
                      //                   "assets/icons/ic_like.svg",
                      //                   colorFilter: ColorFilter.mode(
                      //                     AppThemeData.grey600,
                      //                     BlendMode.srcIn,
                      //                   ),
                      //                 ),
                      //         ),
                      //         onPressed: () async {
                      //           final userId =
                      //               await SqlStorageConst.getFirebaseId();
                      //           if (controller.favouriteList
                      //               .where(
                      //                 (p0) => p0.restaurantId == model.vendorId,
                      //               )
                      //               .isNotEmpty) {
                      //             FavouriteModel favouriteModel = FavouriteModel(
                      //               restaurantId: model.vendorId,
                      //               userId: userId,
                      //             );
                      //             controller.favouriteList.removeWhere(
                      //               (item) => item.restaurantId == model.vendorId,
                      //             );
                      //             await FireStoreUtils.removeFavouriteRestaurant(
                      //               favouriteModel,
                      //             );
                      //           } else {
                      //             FavouriteModel favouriteModel = FavouriteModel(
                      //               restaurantId: model.vendorId,
                      //               userId: userId,
                      //             );
                      //             controller.favouriteList.add(favouriteModel);
                      //             await FireStoreUtils.setFavouriteRestaurant(
                      //               favouriteModel,
                      //             );
                      //           }
                      //         },
                      //       )
                      //     :         // model.type == 'restaurant_promotion'
                      //     ? IconButton(
                      //         icon: Obx(
                      //           () =>
                      //               controller.favouriteList
                      //                   .where(
                      //                     (p0) => p0.restaurantId == model.vendorId,
                      //                   )
                      //                   .isNotEmpty
                      //               ? SvgPicture.asset(
                      //                   "assets/icons/ic_like_fill.svg",
                      //                 )
                      //               : SvgPicture.asset(
                      //                   "assets/icons/ic_like.svg",
                      //                   colorFilter: ColorFilter.mode(
                      //                     AppThemeData.grey600,
                      //                     BlendMode.srcIn,
                      //                   ),
                      //                 ),
                      //         ),
                      //         onPressed: () async {
                      //           final userId =
                      //               await SqlStorageConst.getFirebaseId();
                      //           if (controller.favouriteList
                      //               .where(
                      //                 (p0) => p0.restaurantId == model.vendorId,
                      //               )
                      //               .isNotEmpty) {
                      //             FavouriteModel favouriteModel = FavouriteModel(
                      //               restaurantId: model.vendorId,
                      //               userId: userId,
                      //             );
                      //             controller.favouriteList.removeWhere(
                      //               (item) => item.restaurantId == model.vendorId,
                      //             );
                      //             await FireStoreUtils.removeFavouriteRestaurant(
                      //               favouriteModel,
                      //             );
                      //           } else {
                      //             FavouriteModel favouriteModel = FavouriteModel(
                      //               restaurantId: model.vendorId,
                      //               userId: userId,
                      //             );
                      //             controller.favouriteList.add(favouriteModel);
                      //             await FireStoreUtils.setFavouriteRestaurant(
                      //               favouriteModel,
                      //             );
                      //           }
                      //         },
                      //       )
                      //     :
                      Container(
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
      },
    );
  }
}
