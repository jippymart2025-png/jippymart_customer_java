import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/constant/category_config.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class ViewAllCategoryProvider extends ChangeNotifier {
  static const Duration _networkTimeout = Duration(seconds: 12);

  bool isLoading = true;
  List<VendorCategoryModel> vendorCategoryModel = <VendorCategoryModel>[];

  void initFunction() {
    getCategoryData();
  }

  Future<void> getCategoryData() async {
    isLoading = true;
    notifyListeners();

    try {
      final headers = await getHeaders();
      final uri = Uri.parse(
        '${AppConst.outletBaseUrl}fm/getHomeOrAllCategories?filter=ALL',
      );
      final response = await http
          .get(uri, headers: headers)
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data =
              responseData['data'] as List<dynamic>? ?? [];
          vendorCategoryModel = data
              .whereType<Map<String, dynamic>>()
              .map(VendorCategoryModel.fromJson)
              .toList();
          _filterCategories();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('[CATEGORY_CONTROLLER] Timeout fetching categories: $e');
      vendorCategoryModel = [];
    } catch (error) {
      debugPrint('[CATEGORY_CONTROLLER] Error fetching categories: $error');
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
        return CategoryConfig.allowedCategoryTitles.contains(
          category.categoryName,
        );
      }).toList();
    } else {
      filteredCategories = vendorCategoryModel.where((category) {
        return CategoryConfig.allowedCategoryIds.contains(
          category.categoryId.toString(),
        );
      }).toList();
    }

    if (CategoryConfig.maxCategoriesToShow != null) {
      filteredCategories = filteredCategories
          .take(CategoryConfig.maxCategoriesToShow!)
          .toList();
    }

    if (CategoryConfig.showOnlyCategoriesWithVendors &&
        Constant.restaurantList != null) {
      final usedCategoryIds = Constant.restaurantList!
          .expand((vendor) => vendor.categoryID ?? [])
          .whereType<String>()
          .toSet();

      filteredCategories = filteredCategories.where((category) {
        return usedCategoryIds.contains(category.categoryId.toString());
      }).toList();
    }

    vendorCategoryModel = filteredCategories;
    notifyListeners();
  }
}
