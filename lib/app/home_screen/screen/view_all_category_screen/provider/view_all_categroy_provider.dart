import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/category_config.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class ViewAllCategoryProvider extends ChangeNotifier {
  bool isLoading = true;
  List<VendorCategoryModel> vendorCategoryModel = <VendorCategoryModel>[];

  void initFunction() {
    getCategoryData();
  }

  Future<void> getCategoryData() async {
    try {
      final uri = Uri.parse('${AppConst.baseUrl}categories');
      final headers = await getHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          vendorCategoryModel = data.map((categoryJson) {
            return VendorCategoryModel.fromJson(categoryJson);
          }).toList();
          _filterCategories();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (error) {
      print('[CATEGORY_CONTROLLER] Error fetching categories: $error');
      // You might want to handle the error state here
      vendorCategoryModel = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
      filteredCategories = filteredCategories
          .take(CategoryConfig.maxCategoriesToShow!)
          .toList();
    }
    // Show only categories with active vendors if enabled
    if (CategoryConfig.showOnlyCategoriesWithVendors &&
        Constant.restaurantList != null) {
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
    notifyListeners();
  }
}
