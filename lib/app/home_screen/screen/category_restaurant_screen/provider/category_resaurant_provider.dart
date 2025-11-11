import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class CategoryRestaurantProvider extends ChangeNotifier {
  bool isLoading = true;

  VendorCategoryModel vendorCategoryModel = VendorCategoryModel();
  List<VendorModel> allNearestRestaurant = <VendorModel>[];

  initFunction(VendorCategoryModel vendorCategoryModels) async {
    vendorCategoryModel = vendorCategoryModels;
    await getZone();
    await getRestaurant();
    Future.delayed(Duration(seconds: 1), () {
      isLoading = false;
      notifyListeners();
    });
    notifyListeners();
  }

  Future getRestaurant() async {
    FireStoreUtils.getAllNearestRestaurantByCategoryId(
      categoryId: vendorCategoryModel.id.toString(),
      isDining: false,
    ).listen((event) async {
      allNearestRestaurant.clear();
      allNearestRestaurant.addAll(event);
    });
  }

  getZone() async {
    // await FireStoreUtils.getZone().then((value) {
    //   if (value != null) {
    //     for (int i = 0; i < value.length; i++) {
    //       if (Constant.isPointInPolygon(
    //           LatLng(Constant.selectedLocation.location!.latitude ?? 0.0,
    //               Constant.selectedLocation.location!.longitude ?? 0.0),
    //           value[i].area!)) {
    //         Constant.selectedZone = value[i];
    //         Constant.isZoneAvailable = true;
    //         break;
    //       } else {
    //         Constant.isZoneAvailable = false;
    //       }
    //     }
    //   }
    // });
  }
}
