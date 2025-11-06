import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:get/get.dart';

class DiscountRestaurantListProvider extends ChangeNotifier {
  bool isLoading = true;
  List<VendorModel> vendorList = <VendorModel>[];
  List<CouponModel> couponList = <CouponModel>[];
  String title = "Restaurants";

  void initFunction() {
    getArgument();
  }
  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vendorList = argumentData['vendorList'];
      couponList = argumentData['couponList'];
      title = argumentData['title'] ?? "Restaurants";
    }
    isLoading = false;
  }
}