import 'package:jippymart_customer/app/home_screen/screen/category_restaurant_screen/category_restaurant_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/category_restaurant_screen/provider/category_resaurant_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/view_all_category_screen/provider/view_all_categroy_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ViewAllCategoryScreen extends StatefulWidget {
  const ViewAllCategoryScreen({super.key});

  @override
  State<ViewAllCategoryScreen> createState() => _ViewAllCategoryScreenState();
}

class _ViewAllCategoryScreenState extends State<ViewAllCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ViewAllCategoryProvider>().getCategoryData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewAllCategoryProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppThemeData.grey50,
          appBar: AppBar(
            backgroundColor: AppThemeData.surface,
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              "Categories".tr,
              style: TextStyle(
                fontSize: 18,
                color: AppThemeData.grey900,
                fontFamily: AppThemeData.extraBold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: controller.isLoading
              ? Constant.loader()
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 4,
                          radius: const Radius.circular(10),
                          child: GridView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: controller.vendorCategoryModel.length,
                            itemBuilder: (context, index) {
                              VendorCategoryModel vendorCategoryModel =
                                  controller.vendorCategoryModel[index];
                              return _buildCategoryItem(
                                vendorCategoryModel,
                                context,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCategoryItem(
    VendorCategoryModel category,
    BuildContext context,
  ) {
    return Consumer<CategoryRestaurantProvider>(
      builder: (context, categoryRestaurantProvider, _) {
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shadowColor: Colors.grey.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: AppThemeData.grey50,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              categoryRestaurantProvider.initFunction(
                vendorCategoryModels: category,
                context: context,
              );

              Get.to(const CategoryRestaurantScreen());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category image
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: NetworkImageWidget(
                          imageUrl: category.categoryImageUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Category name
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      category.categoryName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppThemeData.grey900,
                        fontFamily: AppThemeData.medium,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
