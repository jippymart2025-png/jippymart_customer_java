import 'package:jippymart_customer/app/advertisement_screens/provider/all_advertisement_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/favourite_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/video_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:jippymart_customer/utils/color_utils.dart';

class AllAdvertisementScreen extends StatelessWidget {
  const AllAdvertisementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AllAdvertisementProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              "Highlights for you".tr,
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
              : controller.advertisementList.isEmpty
              ? Constant.showEmptyView(message: "Highlights for you not found.")
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.advertisementList.length,
                    padding: EdgeInsets.all(0),
                    itemBuilder: (BuildContext context, int index) {
                      return AdvertisementCard(
                        controller: controller,
                        model: controller.advertisementList[index],
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

class AdvertisementCard extends StatelessWidget {
  final AdvertisementModel model;
  final AllAdvertisementProvider controller;

  const AdvertisementCard({
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
        margin: EdgeInsets.only(bottom: 16),
        width: Responsive.width(80, context),
        decoration: BoxDecoration(
          color: AppThemeData.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ColorUtils.withOpacity(Colors.black, 0.1),
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
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : VideoAdvWidget(
                        url: model.video ?? '',
                        height: 150,
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
                                      "${model.showRating == true ? Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString()) : ''}${model.showRating == true && model.showReview == true ? ' ' : ''}${model.showReview == true ? '(${vendorModel.reviewsCount!.toStringAsFixed(0)})' : ''}",
                                      style: TextStyle(
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          model.description ?? '',
                          style: TextStyle(
                            fontSize: 14,
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
                      ? Obx(
                          () => IconButton(
                            icon:
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
                            onPressed: () async {
                              if (controller.favouriteList
                                  .where(
                                    (p0) => p0.restaurantId == model.vendorId,
                                  )
                                  .isNotEmpty) {
                                final userId =
                                    await SqlStorageConst.getFirebaseId();
                                FavouriteModel favouriteModel = FavouriteModel(
                                  restaurantId: model.vendorId,
                                  userId: userId,
                                );
                                controller.favouriteList.removeWhere(
                                  (item) => item.restaurantId == model.vendorId,
                                );
                                await FireStoreUtils.removeFavouriteRestaurant(
                                  favouriteModel,
                                );
                              } else {
                                final userId =
                                    await SqlStorageConst.getFirebaseId();
                                FavouriteModel favouriteModel = FavouriteModel(
                                  restaurantId: model.vendorId,
                                  userId: userId,
                                );
                                controller.favouriteList.add(favouriteModel);
                                await FireStoreUtils.setFavouriteRestaurant(
                                  favouriteModel,
                                );
                              }
                            },
                          ),
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
