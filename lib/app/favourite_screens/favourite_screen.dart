import 'package:jippymart_customer/app/auth_screen/login_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/widget/restaurant_image_view.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashBoardProvider>(
      builder: (context, controller, _) {
        return Consumer<FavouriteProvider>(
          builder: (context, favouriteProvider, _) {
            return Scaffold(
              backgroundColor: AppThemeData.surface,
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(ImageConst.backgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
                child: favouriteProvider.isLoading
                    ? const AppLoadingWidget(
                        title: "🍕 Loading Your Favorites",
                        subtitle:
                            "Getting your favorite restaurants & dishes...",
                        icon: Icons.local_pizza,
                        backgroundColor: Color(0xFFFF5201),
                        size: 70,
                        showDots: true,
                        showFunFact: true,
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Your Favourites, All in One Place".tr,
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: AppThemeData.grey900,
                                        fontFamily: AppThemeData.semiBold,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    "assets/images/ic_favourite.svg",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: Constant.userModel == null
                                  ? _buildLoginRequiredView()
                                  : _buildFavouriteContent(
                                      favouriteProvider,
                                      context,
                                    ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoginRequiredView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/images/login.gif", height: 120),
          const SizedBox(height: 12),
          Text(
            "Please Log In to Continue".tr,
            style: TextStyle(
              color: AppThemeData.grey800,
              fontSize: 22,
              fontFamily: AppThemeData.semiBold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "You're not logged in. Please sign in to access your account and explore all features."
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
            title: "Log in".tr,
            width: 55,
            height: 5.5,
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () async {
              Get.offAll(const LoginScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavouriteContent(
    FavouriteProvider favouriteProvider,
    BuildContext context,
  ) {
    return Column(
      children: [
        _buildTabBar(favouriteProvider),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: favouriteProvider.favouriteRestaurant
                ? _buildRestaurantList(favouriteProvider, context)
                : _buildFoodList(favouriteProvider, context),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(FavouriteProvider favouriteProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: ShapeDecoration(
          color: AppThemeData.grey200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(120),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    favouriteProvider.changeTabUpdate(true);
                  },
                  child: Container(
                    decoration: favouriteProvider.favouriteRestaurant == false
                        ? null
                        : ShapeDecoration(
                            color: AppThemeData.primary300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(120),
                            ),
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        "Favourite Restaurants".tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: AppThemeData.semiBold,
                          color: favouriteProvider.favouriteRestaurant == true
                              ? AppThemeData.surface
                              : AppThemeData.grey500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    favouriteProvider.changeTabUpdate(false);
                  },
                  child: Container(
                    decoration: favouriteProvider.favouriteRestaurant == true
                        ? null
                        : ShapeDecoration(
                            color: AppThemeData.primary300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(120),
                            ),
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        "Favourite Foods".tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: AppThemeData.semiBold,
                          color: favouriteProvider.favouriteRestaurant == true
                              ? AppThemeData.grey500
                              : AppThemeData.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantList(
    FavouriteProvider favouriteProvider,
    BuildContext context,
  ) {
    if (favouriteProvider.favouriteVendorList.isEmpty) {
      return Constant.showEmptyView(
        message: "Favourite Restaurants not found.".tr,
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.vertical,
      itemCount: favouriteProvider.favouriteVendorList.length,
      itemBuilder: (BuildContext context, int index) {
        VendorModel vendorModel = favouriteProvider.favouriteVendorList[index];
        return _buildRestaurantItem(
          vendorModel,
          favouriteProvider,
          index,
          context,
        );
      },
    );
  }

  Widget _buildRestaurantItem(
    VendorModel vendorModel,
    FavouriteProvider favouriteProvider,
    int index,
    BuildContext context,
  ) {
    return Consumer<RestaurantDetailsProvider>(
      builder: (context, restaurantDetailsProvider, _) {
        return InkWell(
          onTap: () {
            if (vendorModel.zoneId == Constant.selectedZone!.id) {
              ShowToastDialog.closeLoader();
              restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
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
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              decoration: ShapeDecoration(
                color: AppThemeData.grey50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            RestaurantImageView(vendorModel: vendorModel),
                            Container(
                              height: Responsive.height(20, context),
                              width: Responsive.width(100, context),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: const Alignment(-0.00, -1.00),
                                  end: const Alignment(0, 1),
                                  colors: [
                                    Colors.black.withOpacity(0),
                                    const Color(0xFF111827),
                                  ],
                                ),
                              ),
                            ),
                            // Favorite remove button for restaurants
                            Positioned(
                              right: 10,
                              top: 10,
                              child: InkWell(
                                onTap: () async {
                                  try {
                                    await favouriteProvider
                                        .removeFavoriteRestaurantUI(
                                          vendorModel.id.toString(),
                                          index,
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Removed from favorites'.tr,
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to remove: Please try again'
                                              .tr,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: SvgPicture.asset(
                                  "assets/icons/ic_like_fill.svg",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(
                          Responsive.width(-3, context),
                          Responsive.height(17.5, context),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Visibility(
                              visible:
                                  (vendorModel.isSelfDelivery == true &&
                                  Constant.isSelfDeliveryFeature == true),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppThemeData.lightGreen,
                                      borderRadius: BorderRadius.circular(120),
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_free_delivery.svg",
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Free Delivery".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppThemeData.darkGreen,
                                            fontFamily: AppThemeData.semiBold,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: ShapeDecoration(
                                color: AppThemeData.primary50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(120),
                                ),
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
                                    "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                    style: TextStyle(
                                      color: AppThemeData.primary300,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: ShapeDecoration(
                                color: AppThemeData.secondary50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(120),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_map_distance.svg",
                                    colorFilter: const ColorFilter.mode(
                                      AppThemeData.secondary300,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${Constant.getDistance(lat1: vendorModel.latitude.toString(), lng1: vendorModel.longitude.toString(), lat2: Constant.selectedLocation.location!.latitude.toString(), lng2: Constant.selectedLocation.location!.longitude.toString())} ${Constant.distanceType}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppThemeData.secondary300,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorModel.title.toString(),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 18,
                            overflow: TextOverflow.ellipsis,
                            fontFamily: AppThemeData.semiBold,
                            color: AppThemeData.grey900,
                          ),
                        ),
                        Text(
                          vendorModel.location.toString(),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontFamily: AppThemeData.medium,
                            fontWeight: FontWeight.w500,
                            color: AppThemeData.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodList(
    FavouriteProvider favouriteProvider,
    BuildContext context,
  ) {
    if (favouriteProvider.favouriteFoodList.isEmpty) {
      return Constant.showEmptyView(message: "Favourite Foods not found.".tr);
    }

    return ListView.builder(
      itemCount: favouriteProvider.favouriteFoodList.length,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        ProductModel productModel = favouriteProvider.favouriteFoodList[index];
        return _buildFoodItem(productModel, favouriteProvider, index, context);
      },
    );
  }

  Widget _buildFoodItem(
    ProductModel productModel,
    FavouriteProvider favouriteProvider,
    int index,
    BuildContext context,
  ) {
    return FutureBuilder(
      future: getPrice(productModel),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: AppLoadingWidget(
                title: "🍕 Loading Food Details",
                subtitle: "Getting price and details...",
                icon: Icons.local_pizza,
                backgroundColor: Color(0xFFFF5201),
                size: 100,
                showDots: true,
                showFunFact: false,
              ),
            ),
          );
        } else {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null) {
            return const SizedBox();
          } else {
            Map<String, dynamic> map = snapshot.data!;
            String price = map['price'];
            String disPrice = map['disPrice'];

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: ShapeDecoration(
                color: AppThemeData.grey50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: NetworkImageWidget(
                            imageUrl: productModel.photo.toString(),
                            fit: BoxFit.cover,
                            height: 100,
                            width: 100,
                          ),
                        ),
                        // Veg/Non-Veg Indicator
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: productModel.nonveg == true
                                ? SvgPicture.asset(
                                    "assets/icons/ic_nonveg.svg",
                                    height: 12,
                                  )
                                : SvgPicture.asset(
                                    "assets/icons/ic_veg.svg",
                                    height: 12,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Food Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  productModel.name.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppThemeData.grey900,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Favorite remove button
                              InkWell(
                                onTap: () async {
                                  try {
                                    await favouriteProvider
                                        .removeFavoriteFoodUI(
                                          productModel.id!,
                                          index,
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Removed from favorites'.tr,
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to remove: Please try again'
                                              .tr,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: SvgPicture.asset(
                                  "assets/icons/ic_like_fill.svg",
                                  colorFilter: ColorFilter.mode(
                                    AppThemeData.primary300,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Rating
                          Row(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/ic_star.svg",
                                colorFilter: const ColorFilter.mode(
                                  AppThemeData.warning300,
                                  BlendMode.srcIn,
                                ),
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                Constant.calculateReview(
                                  reviewCount: productModel.reviewsCount!
                                      .toStringAsFixed(0),
                                  reviewSum: productModel.reviewsSum.toString(),
                                ),
                                style: TextStyle(
                                  color: AppThemeData.grey700,
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                " (${productModel.reviewsCount!.toStringAsFixed(0)})",
                                style: TextStyle(
                                  color: AppThemeData.grey500,
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Description
                          Text(
                            productModel.description ?? "",
                            style: TextStyle(
                              color: AppThemeData.grey600,
                              fontFamily: AppThemeData.regular,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Row(
                            children: [
                              if (double.parse(disPrice) > 0 &&
                                  double.parse(disPrice) < double.parse(price))
                                Text(
                                  Constant.amountShow(amount: disPrice),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppThemeData.primary300,
                                    fontFamily: AppThemeData.bold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (double.parse(disPrice) > 0 &&
                                  double.parse(disPrice) < double.parse(price))
                                const SizedBox(width: 8),
                              Text(
                                Constant.amountShow(amount: price),
                                style: TextStyle(
                                  fontSize:
                                      double.parse(disPrice) > 0 &&
                                          double.parse(disPrice) <
                                              double.parse(price)
                                      ? 14
                                      : 18,
                                  color:
                                      double.parse(disPrice) > 0 &&
                                          double.parse(disPrice) <
                                              double.parse(price)
                                      ? AppThemeData.grey500
                                      : AppThemeData.primary300,
                                  fontFamily: AppThemeData.bold,
                                  fontWeight: FontWeight.w700,
                                  decoration:
                                      double.parse(disPrice) > 0 &&
                                          double.parse(disPrice) <
                                              double.parse(price)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ],
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
      },
    );
  }

  // Future<Map<String, dynamic>> getPrice(ProductModel productModel) async {
  //   String price = "0.0";
  //   String disPrice = "0.0";
  //   List<String> selectedVariants = [];
  //   List<String> selectedIndexVariants = [];
  //   List<String> selectedIndexArray = [];
  //   VendorModel? vendorModel = await FireStoreUtils.getVendorById(
  //     productModel.vendorID.toString(),
  //   );
  //
  //   if (productModel.itemAttribute != null) {
  //     if (productModel.itemAttribute!.attributes!.isNotEmpty) {
  //       for (var element in productModel.itemAttribute!.attributes!) {
  //         if (element.attributeOptions!.isNotEmpty) {
  //           selectedVariants.add(
  //             productModel
  //                 .itemAttribute!
  //                 .attributes![productModel.itemAttribute!.attributes!.indexOf(
  //                   element,
  //                 )]
  //                 .attributeOptions![0]
  //                 .toString(),
  //           );
  //           selectedIndexVariants.add(
  //             '${productModel.itemAttribute!.attributes!.indexOf(element)} _${productModel.itemAttribute!.attributes![0].attributeOptions![0].toString()}',
  //           );
  //           selectedIndexArray.add(
  //             '${productModel.itemAttribute!.attributes!.indexOf(element)}_0',
  //           );
  //         }
  //       }
  //     }
  //     if (productModel.itemAttribute!.variants!
  //         .where((element) => element.variantSku == selectedVariants.join('-'))
  //         .isNotEmpty) {
  //       price = Constant.productCommissionPrice(
  //         vendorModel!,
  //         productModel.itemAttribute!.variants!
  //                 .where(
  //                   (element) =>
  //                       element.variantSku == selectedVariants.join('-'),
  //                 )
  //                 .first
  //                 .variantPrice ??
  //             '0',
  //       );
  //       disPrice = Constant.productCommissionPrice(vendorModel, '0');
  //     }
  //   } else {
  //     price = Constant.productCommissionPrice(
  //       vendorModel!,
  //       productModel.price.toString(),
  //     );
  //     disPrice = Constant.productCommissionPrice(
  //       vendorModel,
  //       productModel.disPrice.toString(),
  //     );
  //   }
  //
  //   return {'price': price, 'disPrice': disPrice};
  // }
  Future<Map<String, dynamic>> getPrice(ProductModel productModel) async {
    String price = "0.0";
    String disPrice = "0.0";
    List<String> selectedVariants = [];
    List<String> selectedIndexVariants = [];
    List<String> selectedIndexArray = [];

    VendorModel? vendorModel = await FireStoreUtils.getVendorById(
      productModel.vendorID.toString(),
    );

    if (vendorModel == null) {
      debugPrint('⚠️ Vendor not found for ID: ${productModel.vendorID}');
      return {
        'price': productModel.price ?? '0',
        'disPrice': productModel.disPrice ?? '0',
      };
    }

    final attrs = productModel.itemAttribute?.attributes ?? [];
    final variants = productModel.itemAttribute?.variants ?? [];

    if (attrs.isNotEmpty) {
      for (var i = 0; i < attrs.length; i++) {
        final element = attrs[i];
        if (element.attributeOptions != null &&
            element.attributeOptions!.isNotEmpty) {
          final option = element.attributeOptions!.first;
          selectedVariants.add(option);
          selectedIndexVariants.add('$i$option');
          selectedIndexArray.add('${i}_0');
        }
      }

      final matchedVariant = variants.firstWhere(
        (v) => v.variantSku == selectedVariants.join('-'),
        orElse: () => Variants(variantPrice: '0'),
      );

      price = Constant.productCommissionPrice(
        vendorModel,
        matchedVariant.variantPrice ?? '0',
      );
      disPrice = Constant.productCommissionPrice(vendorModel, '0');
    } else {
      price = Constant.productCommissionPrice(
        vendorModel,
        productModel.price?.toString() ?? '0',
      );
      disPrice = Constant.productCommissionPrice(
        vendorModel,
        productModel.disPrice?.toString() ?? '0',
      );
    }

    return {'price': price, 'disPrice': disPrice};
  }
}
