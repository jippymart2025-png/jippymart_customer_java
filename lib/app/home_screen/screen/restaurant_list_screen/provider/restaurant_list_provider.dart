import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/favourite_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';

class RestaurantListProvider extends ChangeNotifier {
  bool isLoading = false;

  void isLoadingFunction(bool value) {
    isLoading = value;
    notifyListeners();
  }

  List<VendorModel> vendorList = <VendorModel>[];
  List<VendorModel> vendorSearchList = <VendorModel>[];

  String title = "Restaurants";

  List<FavouriteModel> favouriteList = <FavouriteModel>[];

  void initFunction({
    required List<VendorModel> vendorLists,
    String titles = 'Restaurants',
  }) async {
    isLoadingFunction(true);
    vendorList = vendorLists;
    vendorSearchList = vendorLists;
    title = titles;
    notifyListeners();
    await getFavouriteRestaurant();
    isLoadingFunction(false);
  }

  getFavouriteRestaurant() async {
    if (Constant.userModel != null) {
      await FireStoreUtils.getFavouriteRestaurant().then((value) {
        favouriteList = value;
      });
    }
  }

  void disposeFunction() {
    vendorSearchList.clear();
  }
}
