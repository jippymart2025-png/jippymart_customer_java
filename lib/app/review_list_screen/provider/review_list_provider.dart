import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/rating_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class ReviewListProvider extends ChangeNotifier {
  RxBool isLoading = true.obs;

  void initFunction() {
    getArgument();
  }

  Rx<VendorModel> vendorModel = VendorModel().obs;
  RxList<RatingModel> ratingList = <RatingModel>[].obs;

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vendorModel.value = argumentData['vendorModel'];
      getAllReview();
    }
    isLoading.value = false;
  }

  getAllReview() async {
    await FireStoreUtils.getVendorReviews(vendorModel.value.id.toString()).then(
          (value) {
        ratingList.value = value;
      },
    );
    notifyListeners();
  }
}
