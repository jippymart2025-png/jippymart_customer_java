import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/rating_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';

class ReviewListProvider extends ChangeNotifier {
  bool isLoading = true;

  VendorModel vendorModel = VendorModel();
  List<RatingModel> ratingList = <RatingModel>[];

  initFunction({required VendorModel vendorModels}) {
    vendorModel = vendorModels;
    getAllReview();
    isLoading = false;
    notifyListeners();
  }

  getAllReview() async {
    log("getAllReview  ${vendorModel.toJson()}");
    await FireStoreUtils.getVendorReviews(vendorModel.id.toString()).then((
      value,
    ) {
      ratingList = value;
      notifyListeners();
    });
    notifyListeners();
  }
}
