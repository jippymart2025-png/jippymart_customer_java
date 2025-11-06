import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';

class AddressListProvider extends ChangeNotifier{
  UserModel userModel = UserModel();
  List<ShippingAddress> shippingAddressList = <ShippingAddress>[];
  List saveAsList = ['Home', 'Work', 'Hotel', 'other'];
  String selectedSaveAs = "Home";
  TextEditingController houseBuildingTextEditingController = TextEditingController();
  TextEditingController localityEditingController = TextEditingController();
  TextEditingController landmarkEditingController = TextEditingController();
  String localityText = "";
  UserLocation location = UserLocation();
  ShippingAddress shippingModel = ShippingAddress();
  bool isLoading = false;
  void initFunction() {
    getUser();
  }
  clearData() {
    shippingModel = ShippingAddress();
    houseBuildingTextEditingController.clear();
    localityEditingController.clear();
    landmarkEditingController.clear();
    localityText = ""; // Clear reactive string
    location = UserLocation();
    selectedSaveAs = "Home";
  }
  setData(ShippingAddress shippingAddress) {
    shippingModel = shippingAddress;
    houseBuildingTextEditingController.text = shippingAddress.address.toString();
    localityEditingController.text = shippingAddress.locality.toString();
    localityText = shippingAddress.locality.toString(); // Set reactive string
    landmarkEditingController.text = shippingAddress.landmark.toString();
    selectedSaveAs = shippingAddress.addressAs.toString();
    location = shippingAddress.location??UserLocation();
    notifyListeners();
  }

  getUser() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then(
          (value) {
        if (value != null) {
          userModel = value;
          if (userModel.shippingAddress != null) {
            shippingAddressList = userModel.shippingAddress!;
          }
        }
      },
    );
  }
}