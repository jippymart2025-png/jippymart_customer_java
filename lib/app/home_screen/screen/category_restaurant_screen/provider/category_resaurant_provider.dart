import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class CategoryRestaurantProvider extends ChangeNotifier {
  // ── State ────────────────────────────────────────────────
  bool isLoading = true;
  String? errorMessage;

  VendorCategoryModel vendorCategoryModel = VendorCategoryModel();
  List<VendorModel> allNearestRestaurant = <VendorModel>[];

  late HomeProvider _homeProvider;

  // ── Init ─────────────────────────────────────────────────
  Future<void> initFunction({
    required VendorCategoryModel vendorCategoryModels,
    required BuildContext context,
  }) async {
    _homeProvider = Provider.of<HomeProvider>(context, listen: false);
    vendorCategoryModel = vendorCategoryModels;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _homeProvider.getZone();
    await _fetchRestaurants();

    isLoading = false;
    notifyListeners();
  }

  static Future<Map<String, dynamic>> _getAllNearestRestaurantByCategoryId({
    required String categoryId,
    required double latitude,
    required double longitude,
    required String zoneid,
    double radius = 20,
    String filter = 'distance',
    bool? isDining,
  }) async {
    final uri = Uri.parse(
      '${AppConst.baseUrl}vendors/$categoryId/category?'
      'latitude=$latitude'
      '&longitude=$longitude'
      '&zoneid=$zoneid' // ✅ FIXED
      '&radius=$radius'
      '&filter=$filter'
      '${isDining != null ? '&isDining=$isDining' : ''}',
    );

    final response = await http.get(uri, headers: await getHeaders());

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load restaurants (${response.statusCode})');
  }

  // ── Fetch & filter ───────────────────────────────────────
  Future<void> _fetchRestaurants() async {
    try {
      final double latitude =
          Constant.selectedLocation.location?.latitude ?? 0.0;
      final double longitude =
          Constant.selectedLocation.location?.longitude ?? 0.0;

      if (Constant.selectedZone?.id == null) {
        debugPrint('[CategoryRestaurantProvider] No zone selected — aborting.');
        return;
      }

      final response = await _getAllNearestRestaurantByCategoryId(
        categoryId: vendorCategoryModel.id.toString(),
        zoneid: Constant.selectedZone!.id.toString(),
        latitude: latitude,
        longitude: longitude,
        radius: double.tryParse(Constant.radius) ?? 20,
      );

      debugPrint(
        '[CategoryRestaurantProvider] Raw response: ${response['data']}',
      );

      if (response['success'] != true) {
        debugPrint(
          '[CategoryRestaurantProvider] API error: ${response['message']}',
        );
        return;
      }

      final List<dynamic> rawList = response['data'] as List<dynamic>? ?? [];
      final List<VendorModel> parsed = [];

      for (final item in rawList) {
        try {
          final VendorModel vendor = VendorModel.fromJson(item);

          // Exclude mart type regardless of subscription
          if (vendor.vType?.toLowerCase() == 'mart') continue;

          // Apply subscription / commission filter
          if ((Constant.isSubscriptionModelApplied == true ||
                  Constant.adminCommission?.isEnabled == true) &&
              vendor.subscriptionPlan != null) {
            if (!_isSubscriptionValid(vendor)) continue;
          }

          parsed.add(vendor);
        } catch (e) {
          debugPrint('[CategoryRestaurantProvider] Parse error: $e');
        }
      }

      allNearestRestaurant
        ..clear()
        ..addAll(parsed);

      debugPrint(
        '[CategoryRestaurantProvider] Total vendors: ${allNearestRestaurant.length}',
      );
    } catch (e, st) {
      errorMessage = e.toString();
      debugPrint('[CategoryRestaurantProvider] Error: $e\n$st');
    }
  }

  // ── Subscription validity helper ─────────────────────────
  bool _isSubscriptionValid(VendorModel vendor) {
    // Unlimited orders
    if (vendor.subscriptionTotalOrders == '-1') return true;

    // Check expiry
    final bool notExpired =
        vendor.subscriptionExpiryDate != null &&
        !vendor.subscriptionExpiryDate!.toDate().isBefore(DateTime.now());

    final bool neverExpires = vendor.subscriptionPlan?.expiryDay == '-1';

    if (!notExpired && !neverExpires) return false;

    // Check remaining orders
    return vendor.subscriptionTotalOrders != '0';
  }

  // ── Public refresh ───────────────────────────────────────
  Future<void> refresh(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    await _fetchRestaurants();
    isLoading = false;
    notifyListeners();
  }
}
