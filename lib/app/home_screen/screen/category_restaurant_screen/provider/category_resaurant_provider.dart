import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CategoryRestaurantProvider extends ChangeNotifier {
  bool isLoading = true;

  VendorCategoryModel vendorCategoryModel = VendorCategoryModel();
  List<VendorModel> allNearestRestaurant = <VendorModel>[];
  late HomeProvider homeProvider;

  initFunction({
    required VendorCategoryModel vendorCategoryModels,
    required BuildContext context,
  }) async {
    homeProvider = Provider.of(context, listen: false);
    vendorCategoryModel = vendorCategoryModels;
    await homeProvider.getZone();
    await getRestaurant();
    isLoading = false;
    notifyListeners();
  }

  static Future<Map<String, dynamic>> getAllNearestRestaurantByCategoryId({
    required String categoryId,
    required double latitude,
    required double longitude,
    double radius = 20,
    String filter = 'distance',
    bool? isDining,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}vendors/$categoryId/category?'
          'latitude=$latitude'
          '&longitude=$longitude'
          '&radius=$radius'
          '&filter=$filter'
          '${isDining != null ? '&isDining=$isDining' : ''}',
        ),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getRestaurant() async {
    try {
      final String? zoneId = Constant.selectedZone?.id;
      final double latitude =
          Constant.selectedLocation.location?.latitude ?? 0.0;
      final double longitude =
          Constant.selectedLocation.location?.longitude ?? 0.0;
      if (zoneId == null) {
        return;
      }
      final response = await getAllNearestRestaurantByCategoryId(
        categoryId: vendorCategoryModel.id.toString(),
        latitude: latitude,
        longitude: longitude,
        radius: double.parse(Constant.radius),
      );
      print("getRestaurant " + response['data'].toString());
      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        allNearestRestaurant.clear();
        for (var vendorData in data) {
          try {
            VendorModel vendorModel = VendorModel.fromJson(vendorData);
            if ((Constant.isSubscriptionModelApplied == true ||
                    Constant.adminCommission?.isEnabled == true) &&
                vendorModel.subscriptionPlan != null) {
              if (vendorModel.subscriptionTotalOrders == "-1") {
                if (vendorModel.vType == null ||
                    vendorModel.vType!.toLowerCase() != 'mart') {
                  allNearestRestaurant.add(vendorModel);
                }
              } else {
                if ((vendorModel.subscriptionExpiryDate != null &&
                        vendorModel.subscriptionExpiryDate!.toDate().isBefore(
                              DateTime.now(),
                            ) ==
                            false) ||
                    vendorModel.subscriptionPlan?.expiryDay == '-1') {
                  if (vendorModel.subscriptionTotalOrders != '0') {
                    if (vendorModel.vType == null ||
                        vendorModel.vType!.toLowerCase() != 'mart') {
                      allNearestRestaurant.add(vendorModel);
                    }
                  }
                }
              }
            } else {
              if (vendorModel.vType == null ||
                  vendorModel.vType!.toLowerCase() != 'mart') {
                allNearestRestaurant.add(vendorModel);
              }
            }
          } catch (e) {
            print('Error parsing vendor data: $e');
          }
        }
        print("Total vendors found: ${allNearestRestaurant.length}");
      } else {
        print("API returned unsuccessful response: ${response['message']}");
      }
    } catch (e) {
      print("Error in getRestaurant: $e");
    }
  }
}
