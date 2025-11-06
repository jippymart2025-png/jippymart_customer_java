import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/favourite_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';

class RestaurantListProvider extends ChangeNotifier{
  bool isLoading = true;
  List<VendorModel> vendorList = <VendorModel>[];
  List<VendorModel> vendorSearchList = <VendorModel>[];

  String title = "Restaurants";

  List<FavouriteModel> favouriteList = <FavouriteModel>[];

  void initFunction() {
    getArgument();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vendorList = argumentData['vendorList'];
      vendorSearchList = argumentData['vendorList'];
      title = argumentData['title'] ?? "Restaurants";
    }

    await getFavouriteRestaurant();

    isLoading = false;
  }

  getFavouriteRestaurant() async {
    if (Constant.userModel != null) {
      await FireStoreUtils.getFavouriteRestaurant().then(
            (value) {
          favouriteList = value;
        },
      );
    }
  }

  void disposeFunction() {
    vendorSearchList.clear();
  }
}