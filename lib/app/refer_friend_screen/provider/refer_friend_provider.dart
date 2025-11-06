import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/models/referral_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class ReferFriendProvider extends ChangeNotifier {
  Rx<ReferralModel> referralModel = ReferralModel().obs;

  RxBool isLoading = true.obs;

  void initFunction() {
    getData();
  }

  getData() async {
    await FireStoreUtils.getReferralUserBy().then((value) {
      if (value != null) {
        referralModel.value = value;
      }
    });
    isLoading.value = false;
  }
}
