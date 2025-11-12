import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/widget/restaurant_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class RestaurantListScreen extends StatelessWidget {
  const RestaurantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantListProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              controller.title,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 16,
                color: AppThemeData.grey900,
              ),
            ),
          ),
          body: controller.isLoading
              ? Constant.loader()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.vendorSearchList.length,
                    itemBuilder: (context, index) {
                      VendorModel vendorModel =
                          controller.vendorSearchList[index];
                      return Consumer<RestaurantDetailsProvider>(
                        builder: (context, restaurantDetailsProvider, _) {
                          return InkWell(
                            onTap:
                                !RestaurantStatusUtils.canAcceptOrders(
                                  vendorModel,
                                )
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Closed')),
                                    );
                                  }
                                : () {
                                    restaurantDetailsProvider.initFunction(
                                      vendorModels: vendorModel,
                                    );
                                    Get.to(
                                      const RestaurantDetailsScreen(),
                                      arguments: {"vendorModel": vendorModel},
                                    )?.then((v) {
                                      controller.getFavouriteRestaurant();
                                    });
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
                                              RestaurantImageView(
                                                vendorModel: vendorModel,
                                              ),
                                              Container(
                                                height: Responsive.height(
                                                  20,
                                                  context,
                                                ),
                                                width: Responsive.width(
                                                  100,
                                                  context,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: const Alignment(
                                                      -0.00,
                                                      -1.00,
                                                    ),
                                                    end: const Alignment(0, 1),
                                                    colors: [
                                                      Colors.black.withOpacity(
                                                        0,
                                                      ),
                                                      const Color(0xFF111827),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Status badge using new failproof system
                                              Positioned(
                                                left: 0,
                                                top: 0,
                                                child:
                                                    RestaurantStatusUtils.getStatusWidget(
                                                      vendorModel,
                                                    ),
                                              ),
                                              Positioned(
                                                right: 10,
                                                top: 10,
                                                child: InkWell(
                                                  onTap: () async {
                                                    try {
                                                      await controller
                                                          .toggleFavorite(
                                                            vendorModel,
                                                          );
                                                      // Show success message
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            controller.isVendorFavorite(
                                                                  vendorModel.id
                                                                      .toString(),
                                                                )
                                                                ? 'Added to favorites'
                                                                : 'Removed from favorites',
                                                          ),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Operation failed: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child:
                                                      controller
                                                          .isVendorFavorite(
                                                            vendorModel.id
                                                                .toString(),
                                                          )
                                                      ? SvgPicture.asset(
                                                          "assets/icons/ic_like_fill.svg",
                                                        )
                                                      : SvgPicture.asset(
                                                          "assets/icons/ic_like.svg",
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Visibility(
                                                visible:
                                                    (vendorModel
                                                            .isSelfDelivery ==
                                                        true &&
                                                    Constant.isSelfDeliveryFeature ==
                                                        true),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 7,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppThemeData
                                                            .lightGreen,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              120,
                                                            ), // Optional
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          SvgPicture.asset(
                                                            "assets/icons/ic_free_delivery.svg",
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            "Free Delivery".tr,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: AppThemeData
                                                                  .darkGreen,
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
                                                    const SizedBox(width: 6),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 7,
                                                    ),
                                                decoration: ShapeDecoration(
                                                  color: AppThemeData.primary50,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          120,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      "assets/icons/ic_star.svg",
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                            AppThemeData
                                                                .primary300,
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppThemeData
                                                            .primary300,
                                                        fontFamily: AppThemeData
                                                            .semiBold,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 7,
                                                    ),
                                                decoration: ShapeDecoration(
                                                  color:
                                                      AppThemeData.secondary50,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          120,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      "assets/icons/ic_map_distance.svg",
                                                      colorFilter:
                                                          const ColorFilter.mode(
                                                            AppThemeData
                                                                .secondary300,
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      "${Constant.getDistanceFromVendor(vendorModel)} ${Constant.distanceType}",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppThemeData
                                                            .secondary300,
                                                        fontFamily: AppThemeData
                                                            .semiBold,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                    },
                  ),
                ),
        );
      },
    );
  }
}
