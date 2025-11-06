import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class ScanQrCodeProvider extends ChangeNotifier {
  void initFunction() {
    getData();
  }

  RxList<VendorModel> allNearestRestaurant = <VendorModel>[].obs;

  getData() {
    FireStoreUtils.getAllNearestRestaurant().listen((event) async {
      allNearestRestaurant.addAll(event);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
