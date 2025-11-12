import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/screen/category_restaurant_screen/category_restaurant_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/category_restaurant_screen/provider/category_resaurant_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/category_view_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/view_all_category_screen/provider/view_all_categroy_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/view_all_category_screen/view_all_category_screen.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:provider/provider.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      CategoryViewProvider,
      ViewAllCategoryProvider,
      CategoryRestaurantProvider
    >(
      builder:
          (
            context,
            controller,
            viewAllCategoryProvider,
            categoryRestaurantProvider,
            _,
          ) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.all(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Our Categories",
                                style: TextStyle(
                                  fontFamily: AppThemeData.montserratRegular,
                                  color: AppThemeData.grey900,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: InkWell(
                                onTap: () {
                                  viewAllCategoryProvider.initFunction();
                                  Get.to(const ViewAllCategoryScreen());
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "See all".tr,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.semiBold,
                                          color: AppThemeData.primary300,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: AppThemeData.primary300,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Best Serving Food".tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.montserrat,
                            // fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      itemCount: controller.vendorCategoryModel.length >= 8
                          ? 8
                          : controller.vendorCategoryModel.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        VendorCategoryModel vendorCategoryModel =
                            controller.vendorCategoryModel[index];
                        return GestureDetector(
                          onTap: () {
                            categoryRestaurantProvider.initFunction(
                              vendorCategoryModel,
                            );
                            Get.to(const CategoryRestaurantScreen());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 0),
                            padding: const EdgeInsets.only(right: 8),

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: 55,
                                      height: 55,
                                      child: NetworkImageWidget(
                                        imageUrl: vendorCategoryModel.photo
                                            .toString(),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    vendorCategoryModel.title ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.medium,
                                      color: AppThemeData.grey900,
                                      fontSize: 12,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
