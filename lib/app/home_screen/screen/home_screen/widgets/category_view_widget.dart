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
            return _CategoryViewBody(
              controller: controller,
              viewAllCategoryProvider: viewAllCategoryProvider,
              categoryRestaurantProvider: categoryRestaurantProvider,
            );
          },
    );
  }
}

class _CategoryViewBody extends StatelessWidget {
  const _CategoryViewBody({
    required this.controller,
    required this.viewAllCategoryProvider,
    required this.categoryRestaurantProvider,
  });

  final CategoryViewProvider controller;
  final ViewAllCategoryProvider viewAllCategoryProvider;
  final CategoryRestaurantProvider categoryRestaurantProvider;

  // static const LinearGradient _cardAccentGradient = LinearGradient(
  //   colors: [Color(0xFFFF6B35), Color(0xFFFF3D77), Color(0xFFD7006A)],
  //   begin: Alignment.centerLeft,
  //   end: Alignment.centerRight,
  // );

  @override
  Widget build(BuildContext context) {
    final count = controller.vendorCategoryModel.length >= 8
        ? 8
        : controller.vendorCategoryModel.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const SizedBox(height: 4),
        Container(
          width: double.infinity, // 👈 ADD THIS
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppThemeData.grey100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppThemeData.primary300.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                width: double.infinity,
                // decoration: const BoxDecoration(gradient: _cardAccentGradient),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Our Categories",
                            style: TextStyle(
                              fontFamily: AppThemeData.extraBold,
                              color: AppThemeData.grey900,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pick a cuisine and explore'.tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.medium,
                              color: AppThemeData.grey500,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: AppThemeData.primary50,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: () {
                          viewAllCategoryProvider.initFunction();
                          Get.to(const ViewAllCategoryScreen());
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "See all".tr,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  color: AppThemeData.primary300,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 17,
                                color: AppThemeData.primary300,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 128,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 16),
                  itemCount: count,
                  itemBuilder: (context, index) {
                    final vendorCategoryModel =
                        controller.vendorCategoryModel[index];
                    return _CategoryCircleTile(
                      category: vendorCategoryModel,
                      onTap: () {
                        categoryRestaurantProvider.initFunction(
                          vendorCategoryModels: vendorCategoryModel,
                          context: context,
                        );
                        Get.to(const CategoryRestaurantScreen());
                      },
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
}

class _CategoryCircleTile extends StatelessWidget {
  final VendorCategoryModel category;
  final VoidCallback onTap;

  const _CategoryCircleTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeData.primary300.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    // decoration: const BoxDecoration(
                    //   shape: BoxShape.circle,
                    //   color: Colors.white,
                    // ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: NetworkImageWidget(
                          imageUrl: category.photo.toString(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 76,
                  child: Text(
                    category.title ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      color: AppThemeData.grey800,
                      fontSize: 11.5,
                      height: 1.15,
                    ),
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
