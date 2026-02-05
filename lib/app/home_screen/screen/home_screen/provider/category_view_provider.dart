import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/services/cache_manager.dart';
import 'package:jippymart_customer/services/api_queue_manager.dart';

class CategoryViewProvider extends ChangeNotifier {
  static const Duration _networkTimeout = Duration(seconds: 12);
  List<VendorCategoryModel> vendorCategoryModel = <VendorCategoryModel>[];

  Future<void> loadVendorCategories() async {
    final categories = await getHomeVendorCategory();
    vendorCategoryModel = categories;
    notifyListeners();
  }

  Future<List<VendorCategoryModel>> getHomeVendorCategory() async {
    const cacheKey = 'categories_home';
    return await CacheManager().getOrSetCategories<List<VendorCategoryModel>>(
      cacheKey,
      () => ApiQueueManager().enqueue<List<VendorCategoryModel>>(
        priority: RequestPriority.high,
        key: cacheKey,
        request: () => _fetchHomeVendorCategory(),
      ),
    );
  }

  Future<List<VendorCategoryModel>> _fetchHomeVendorCategory() async {
    List<VendorCategoryModel> list = [];
    try {
      final headers = await getHeaders();
      final url = Uri.parse('${AppConst.baseUrl}categories/home');
      print('[CATEGORY_API] Fetching home categories from: $url');
      final response = await http
          .get(url, headers: headers)
          .timeout(_networkTimeout);
      print("getHomeVendorCategory ${response.body}");
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          for (var item in data) {
            VendorCategoryModel categoryModel = VendorCategoryModel.fromJson(
              item,
            );
            list.add(categoryModel);
          }
          print('[CATEGORY_API] Home categories loaded: ${list.length}');
        } else {
          print('[CATEGORY_API] API returned success: false');
        }
      } else {
        print('[CATEGORY_API] HTTP error: ${response.statusCode}');
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('[CATEGORY_API] Timeout fetching categories: $e');
    } catch (e) {
      print('[CATEGORY_API] Error fetching categories: $e');
    }
    return list;
  }
}
