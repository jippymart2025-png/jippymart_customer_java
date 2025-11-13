import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/rating_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class ReviewListProvider extends ChangeNotifier {
  bool isLoading = true;

  void initFunction() {
    getArgument();
  }

  VendorModel vendorModel = VendorModel();
  List<RatingModel> ratingList = <RatingModel>[];

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vendorModel = argumentData['vendorModel'];
      getAllReview();
    }
    isLoading = false;
  }

  getAllReview() async {
    await FireStoreUtils.getVendorReviews(vendorModel.id.toString()).then((
      value,
    ) {
      ratingList = value;
    });
    notifyListeners();
  }
}
