import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/category_config.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
class ViewAllCategoryProvider extends ChangeNotifier{
  bool isLoading = true;

  List<VendorCategoryModel> vendorCategoryModel = <VendorCategoryModel>[];

  void initFunction() {
  getCategoryData();
  }

  getCategoryData() async {
  await FireStoreUtils.getVendorCategory().then(
  (value) {
  vendorCategoryModel = value;
  _filterCategories();
  },
  );

  isLoading = false;
  }

  void _filterCategories() {
  if (!CategoryConfig.enableCategoryFiltering) {
  return;
  }
  List<VendorCategoryModel> filteredCategories = [];
  if (CategoryConfig.useTitleFiltering) {
  filteredCategories = vendorCategoryModel.where((category) {
  return category.title != null &&
  CategoryConfig.allowedCategoryTitles.contains(category.title);
  }).toList();
  } else {
  // Filter by category IDs
  filteredCategories = vendorCategoryModel.where((category) {
  return category.id != null &&
  CategoryConfig.allowedCategoryIds.contains(category.id);
  }).toList();
  }
  // Apply maximum limit if specified
  if (CategoryConfig.maxCategoriesToShow != null) {
  filteredCategories = filteredCategories.take(CategoryConfig.maxCategoriesToShow!).toList();
  }
  // Show only categories with active vendors if enabled
  if (CategoryConfig.showOnlyCategoriesWithVendors && Constant.restaurantList != null) {
  List<String> usedCategoryIds = Constant.restaurantList!
      .expand((vendor) => vendor.categoryID ?? [])
      .whereType<String>()
      .toSet()
      .toList();
  filteredCategories = filteredCategories.where((category) {
  return category.id != null && usedCategoryIds.contains(category.id);
  }).toList();
  }
  vendorCategoryModel = filteredCategories;
  print('[CATEGORY_CONTROLLER] Total categories: ${vendorCategoryModel.length}');
  print('[CATEGORY_CONTROLLER] Filtered categories: ${filteredCategories.length}');
  }

}