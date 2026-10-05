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

      final url = Uri.parse(
        '${AppConst.defaultBaseUrl}fm/getHomeOrAllCategories?filter=HOME',
      );

      debugPrint('[CATEGORY_API] Fetching home categories from: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(_networkTimeout);

      debugPrint('[CATEGORY_API] Status: ${response.statusCode}');

      debugPrint('[CATEGORY_API] Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }

      final jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] != true) {
        debugPrint('[CATEGORY_API] API returned success: false');
        return list;
      }

      // IMPORTANT:
      // data is an object, not a List.
      final data = jsonResponse['data'];

      if (data == null || data is! Map<String, dynamic>) {
        debugPrint('[CATEGORY_API] Invalid data format');
        return list;
      }

      // IMPORTANT:
      // The actual category list is inside data['categories'].
      final categories = data['categories'];

      if (categories == null || categories is! List) {
        debugPrint('[CATEGORY_API] categories is missing or not a List');
        return list;
      }

      for (final item in categories) {
        if (item is Map<String, dynamic>) {
          final categoryModel = VendorCategoryModel.fromJson(item);

          list.add(categoryModel);

          debugPrint(
            '[CATEGORY_API] '
            'id=${categoryModel.categoryId}, '
            'name=${categoryModel.categoryName}, '
            'type=${categoryModel.categoryType}, '
            'image=${categoryModel.categoryImageUrl}',
          );
        }
      }

      debugPrint('[CATEGORY_API] Home categories loaded: ${list.length}');

      return list;
    } on TimeoutException catch (e) {
      debugPrint('[CATEGORY_API] Timeout fetching categories: $e');
    } catch (e, stackTrace) {
      debugPrint('[CATEGORY_API] Error fetching categories: $e');
      debugPrint('[CATEGORY_API] StackTrace: $stackTrace');
    }

    return list;
  }
}
