import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/favourite_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';

class AllAdvertisementProvider extends ChangeNotifier {
  bool isLoading = true;

  void initFunction() {
    getAdvertisementList();
    getFavouriteRestaurant();
  }

  List<AdvertisementModel> advertisementList = <AdvertisementModel>[];

  getAdvertisementList() async {
    advertisementList.clear();
    List<VendorModel> allNearestRestaurant = <VendorModel>[];
    FireStoreUtils().getAllNearestRestaurant().listen((event) async {
      allNearestRestaurant.addAll(event);
      await FireStoreUtils.getAllAdvertisement().then((value) {
        List<AdvertisementModel> adsList = value;
        advertisementList.addAll(
          adsList.where(
            (ads) => allNearestRestaurant.any(
              (restaurant) => restaurant.id == ads.vendorId,
            ),
          ),
        );
      });
      isLoading = false;
    });
    notifyListeners();
  }

  List<FavouriteModel> favouriteList = <FavouriteModel>[];
  List<VendorModel> vendorModel = <VendorModel>[];

  getFavouriteRestaurant() async {
    if (Constant.userModel != null) {
      await FavouriteProvider.getFavouriteRestaurants().then((value) {
        vendorModel = value;
      });
    }
  }
}
